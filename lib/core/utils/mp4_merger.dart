import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class Mp4Box {
  final String type;
  final int offset;
  final int headerSize;
  final int payloadOffset;
  final int payloadSize;
  final int totalSize;

  Mp4Box({
    required this.type,
    required this.offset,
    required this.headerSize,
    required this.payloadOffset,
    required this.payloadSize,
    required this.totalSize,
  });

  Uint8List getHeaderBytes(Uint8List fullFileBytes) {
    return fullFileBytes.sublist(offset, payloadOffset);
  }

  Uint8List getPayloadBytes(Uint8List fullFileBytes) {
    return fullFileBytes.sublist(payloadOffset, payloadOffset + payloadSize);
  }
}

class Mp4FileMeta {
  final Uint8List bytes;
  final List<Mp4Box> topBoxes;
  final Mp4Box ftypBox;
  final Mp4Box mdatBox;
  final Mp4Box moovBox;

  Mp4FileMeta({
    required this.bytes,
    required this.topBoxes,
    required this.ftypBox,
    required this.mdatBox,
    required this.moovBox,
  });
}

class Mp4Merger {
  Mp4Merger._();

  static List<Mp4Box> _parseBoxes(Uint8List bytes, [int start = 0, int? end]) {
    final limit = end ?? bytes.length;
    final boxes = <Mp4Box>[];
    var pos = start;
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);

    while (pos + 8 <= limit) {
      var size = data.getUint32(pos);
      final type = String.fromCharCodes(bytes.sublist(pos + 4, pos + 8));
      var headerSize = 8;

      if (size == 1) {
        if (pos + 16 > limit) break;
        size = data.getUint64(pos + 8);
        headerSize = 16;
      } else if (size == 0) {
        size = limit - pos;
      }

      if (size < headerSize || pos + size > limit) break;

      boxes.add(Mp4Box(
        type: type,
        offset: pos,
        headerSize: headerSize,
        payloadOffset: pos + headerSize,
        payloadSize: size - headerSize,
        totalSize: size,
      ));

      pos += size;
    }
    return boxes;
  }

  static Mp4Box? _findBox(Uint8List bytes, List<Mp4Box> boxes, String targetType) {
    for (final b in boxes) {
      if (b.type == targetType) return b;
      if (['moov', 'trak', 'mdia', 'minf', 'stbl'].contains(b.type)) {
        final sub = _parseBoxes(bytes, b.payloadOffset, b.payloadOffset + b.payloadSize);
        final found = _findBox(bytes, sub, targetType);
        if (found != null) return found;
      }
    }
    return null;
  }

  static List<Mp4Box> _findBoxes(Uint8List bytes, List<Mp4Box> boxes, String targetType) {
    final results = <Mp4Box>[];
    for (final b in boxes) {
      if (b.type == targetType) {
        results.add(b);
      } else if (['moov', 'trak', 'mdia', 'minf', 'stbl'].contains(b.type)) {
        final sub = _parseBoxes(bytes, b.payloadOffset, b.payloadOffset + b.payloadSize);
        results.addAll(_findBoxes(bytes, sub, targetType));
      }
    }
    return results;
  }

  static String _getTrackHandler(Uint8List bytes, Mp4Box trakBox) {
    final hdlr = _findBox(bytes, [trakBox], 'hdlr');
    if (hdlr != null && hdlr.payloadSize >= 12) {
      return String.fromCharCodes(bytes.sublist(hdlr.payloadOffset + 8, hdlr.payloadOffset + 12));
    }
    return '';
  }

  static Mp4Box? _findTrakByHandler(Uint8List bytes, List<Mp4Box> topBoxes, String handlerType) {
    final traks = _findBoxes(bytes, topBoxes, 'trak');
    for (final trak in traks) {
      if (_getTrackHandler(bytes, trak) == handlerType) {
        return trak;
      }
    }
    return null;
  }

  static Mp4FileMeta? _parseFileMeta(Uint8List bytes) {
    try {
      final topBoxes = _parseBoxes(bytes);
      Mp4Box? ftypBox;
      Mp4Box? mdatBox;
      Mp4Box? moovBox;

      for (final b in topBoxes) {
        if (b.type == 'ftyp') ftypBox = b;
        if (b.type == 'mdat') mdatBox = b;
        if (b.type == 'moov') moovBox = b;
      }

      if (ftypBox != null && mdatBox != null && moovBox != null) {
        return Mp4FileMeta(
          bytes: bytes,
          topBoxes: topBoxes,
          ftypBox: ftypBox,
          mdatBox: mdatBox,
          moovBox: moovBox,
        );
      }
    } catch (e) {
      debugPrint('Mp4FileMeta parse error: $e');
    }
    return null;
  }

  /// Merges multiple MP4 files into a single playable MP4 file.
  static Future<File?> mergeMp4Files(List<File> files, File outputFile) async {
    if (files.isEmpty) return null;
    if (files.length == 1) {
      await files.first.copy(outputFile.path);
      return outputFile;
    }

    try {
      final metas = <Mp4FileMeta>[];
      for (final f in files) {
        if (!await f.exists()) continue;
        final bytes = await f.readAsBytes();
        final meta = _parseFileMeta(bytes);
        if (meta != null) {
          metas.add(meta);
        }
      }

      if (metas.isEmpty) return null;
      if (metas.length == 1) {
        await outputFile.writeAsBytes(metas.first.bytes);
        return outputFile;
      }

      final ftypBytes = metas.first.ftypBox.getHeaderBytes(metas.first.bytes) +
          metas.first.ftypBox.getPayloadBytes(metas.first.bytes);

      int totalMdatPayloadSize = 0;
      for (final m in metas) {
        totalMdatPayloadSize += m.mdatBox.payloadSize;
      }

      final mdatHeaderBuilder = BytesBuilder();
      final totalMdatBoxSize = totalMdatPayloadSize + 8;
      if (totalMdatBoxSize <= 0xFFFFFFFF) {
        final bData = ByteData(8);
        bData.setUint32(0, totalMdatBoxSize);
        bData.setUint8(4, 0x6D); // 'm'
        bData.setUint8(5, 0x64); // 'd'
        bData.setUint8(6, 0x61); // 'a'
        bData.setUint8(7, 0x74); // 't'
        mdatHeaderBuilder.add(bData.buffer.asUint8List());
      } else {
        final bData = ByteData(16);
        bData.setUint32(0, 1);
        bData.setUint8(4, 0x6D);
        bData.setUint8(5, 0x64);
        bData.setUint8(6, 0x61);
        bData.setUint8(7, 0x74);
        bData.setUint64(8, totalMdatPayloadSize + 16);
        mdatHeaderBuilder.add(bData.buffer.asUint8List());
      }
      final mdatHeaderBytes = mdatHeaderBuilder.takeBytes();
      final newMdatPayloadOffset = ftypBytes.length + mdatHeaderBytes.length;

      final modifiedMoovBytes = _mergeMoovBoxes(metas, newMdatPayloadOffset);
      if (modifiedMoovBytes == null) {
        debugPrint('Moov merge returned null, falling back to copy first file');
        await files.first.copy(outputFile.path);
        return outputFile;
      }

      final outBuilder = BytesBuilder();
      outBuilder.add(ftypBytes);
      outBuilder.add(mdatHeaderBytes);

      for (final m in metas) {
        outBuilder.add(m.mdatBox.getPayloadBytes(m.bytes));
      }

      outBuilder.add(modifiedMoovBytes);

      final combinedBytes = outBuilder.takeBytes();
      await outputFile.writeAsBytes(combinedBytes);
      debugPrint('Mp4Merger successfully merged ${files.length} videos into ${outputFile.path} (${combinedBytes.length} bytes)');
      return outputFile;
    } catch (e) {
      debugPrint('Mp4Merger error: $e');
    }
    return null;
  }

  static Uint8List? _mergeMoovBoxes(List<Mp4FileMeta> metas, int newMdatPayloadOffset) {
    try {
      final base = metas.first;
      final baseBytes = base.bytes;
      final baseMoovPayload = base.moovBox.getPayloadBytes(baseBytes);
      final baseMoovBoxes = _parseBoxes(baseMoovPayload);

      final builder = BytesBuilder();

      for (final box in baseMoovBoxes) {
        if (box.type == 'mvhd') {
          builder.add(_updateMvhd(baseMoovPayload, box, metas));
        } else if (box.type == 'trak') {
          final handlerType = _getTrackHandler(baseMoovPayload, box);
          final updatedTrak = _updateTrak(baseMoovPayload, box, metas, newMdatPayloadOffset, handlerType);
          if (updatedTrak != null) {
            builder.add(updatedTrak);
          } else {
            builder.add(baseMoovPayload.sublist(box.offset, box.offset + box.totalSize));
          }
        } else {
          builder.add(baseMoovPayload.sublist(box.offset, box.offset + box.totalSize));
        }
      }

      final payload = builder.takeBytes();
      final header = ByteData(8);
      header.setUint32(0, payload.length + 8);
      header.setUint8(4, 0x6D); // 'm'
      header.setUint8(5, 0x6F); // 'o'
      header.setUint8(6, 0x6F); // 'o'
      header.setUint8(7, 0x76); // 'v'

      final res = BytesBuilder();
      res.add(header.buffer.asUint8List());
      res.add(payload);
      return res.takeBytes();
    } catch (e) {
      debugPrint('Error merging moov boxes: $e');
      return null;
    }
  }

  static Uint8List _updateMvhd(Uint8List moovPayload, Mp4Box box, List<Mp4FileMeta> metas) {
    final bytes = Uint8List.fromList(moovPayload.sublist(box.offset, box.offset + box.totalSize));
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    final version = data.getUint8(box.payloadOffset - box.offset);

    int baseTimescale = 1000;
    int totalDuration = 0;

    if (version == 0) {
      baseTimescale = data.getUint32(box.payloadOffset - box.offset + 12);
    } else {
      baseTimescale = data.getUint32(box.payloadOffset - box.offset + 20);
    }

    for (final m in metas) {
      final mvhd = _findBox(m.bytes, m.topBoxes, 'mvhd');
      if (mvhd != null) {
        final mvhdData = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + mvhd.payloadOffset, mvhd.payloadSize);
        final v = mvhdData.getUint8(0);
        int tScale = 1000;
        int dur = 0;
        if (v == 0) {
          tScale = mvhdData.getUint32(12);
          dur = mvhdData.getUint32(16);
        } else {
          tScale = mvhdData.getUint32(20);
          dur = mvhdData.getUint64(24);
        }
        final normalizedDur = (tScale > 0) ? (dur * (baseTimescale / tScale)).round() : dur;
        totalDuration += normalizedDur;
      }
    }

    if (version == 0) {
      data.setUint32(box.payloadOffset - box.offset + 16, totalDuration);
    } else {
      data.setUint64(box.payloadOffset - box.offset + 24, totalDuration);
    }

    return bytes;
  }

  static Uint8List? _updateTrak(
    Uint8List baseMoovPayload,
    Mp4Box trakBox,
    List<Mp4FileMeta> metas,
    int newMdatPayloadOffset,
    String handlerType,
  ) {
    try {
      final trakBytes = baseMoovPayload.sublist(trakBox.payloadOffset, trakBox.payloadOffset + trakBox.payloadSize);
      final trakSubBoxes = _parseBoxes(trakBytes);

      final builder = BytesBuilder();

      for (final box in trakSubBoxes) {
        if (box.type == 'tkhd') {
          builder.add(_updateTkhd(trakBytes, box, metas, handlerType));
        } else if (box.type == 'mdia') {
          final updatedMdia = _updateMdia(trakBytes, box, metas, newMdatPayloadOffset, handlerType);
          builder.add(updatedMdia ?? trakBytes.sublist(box.offset, box.offset + box.totalSize));
        } else {
          builder.add(trakBytes.sublist(box.offset, box.offset + box.totalSize));
        }
      }

      final payload = builder.takeBytes();
      final header = ByteData(8);
      header.setUint32(0, payload.length + 8);
      header.setUint8(4, 0x74);
      header.setUint8(5, 0x72);
      header.setUint8(6, 0x61);
      header.setUint8(7, 0x6B);

      final result = BytesBuilder();
      result.add(header.buffer.asUint8List());
      result.add(payload);
      return result.takeBytes();
    } catch (e) {
      debugPrint('Error updating trak: $e');
      return null;
    }
  }

  static Uint8List _updateTkhd(Uint8List trakBytes, Mp4Box box, List<Mp4FileMeta> metas, String handlerType) {
    final bytes = Uint8List.fromList(trakBytes.sublist(box.offset, box.offset + box.totalSize));
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    final version = data.getUint8(box.payloadOffset - box.offset);

    int totalDuration = 0;
    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null) {
        final tkhd = _findBox(m.bytes, [trak], 'tkhd');
        if (tkhd != null) {
          final tData = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + tkhd.payloadOffset, tkhd.payloadSize);
          final v = tData.getUint8(0);
          final dur = (v == 0) ? tData.getUint32(20) : tData.getUint64(28);
          totalDuration += dur;
        }
      }
    }

    if (version == 0) {
      data.setUint32(box.payloadOffset - box.offset + 20, totalDuration);
    } else {
      data.setUint64(box.payloadOffset - box.offset + 28, totalDuration);
    }
    return bytes;
  }

  static Uint8List? _updateMdia(
    Uint8List trakBytes,
    Mp4Box mdiaBox,
    List<Mp4FileMeta> metas,
    int newMdatPayloadOffset,
    String handlerType,
  ) {
    try {
      final mdiaBytes = trakBytes.sublist(mdiaBox.payloadOffset, mdiaBox.payloadOffset + mdiaBox.payloadSize);
      final mdiaBoxes = _parseBoxes(mdiaBytes);
      final builder = BytesBuilder();

      for (final box in mdiaBoxes) {
        if (box.type == 'mdhd') {
          builder.add(_updateMdhd(mdiaBytes, box, metas, handlerType));
        } else if (box.type == 'minf') {
          final updatedMinf = _updateMinf(mdiaBytes, box, metas, newMdatPayloadOffset, handlerType);
          builder.add(updatedMinf ?? mdiaBytes.sublist(box.offset, box.offset + box.totalSize));
        } else {
          builder.add(mdiaBytes.sublist(box.offset, box.offset + box.totalSize));
        }
      }

      final payload = builder.takeBytes();
      final header = ByteData(8);
      header.setUint32(0, payload.length + 8);
      header.setUint8(4, 0x6D);
      header.setUint8(5, 0x64);
      header.setUint8(6, 0x69);
      header.setUint8(7, 0x61);

      final result = BytesBuilder();
      result.add(header.buffer.asUint8List());
      result.add(payload);
      return result.takeBytes();
    } catch (e) {
      return null;
    }
  }

  static Uint8List _updateMdhd(Uint8List mdiaBytes, Mp4Box box, List<Mp4FileMeta> metas, String handlerType) {
    final bytes = Uint8List.fromList(mdiaBytes.sublist(box.offset, box.offset + box.totalSize));
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    final version = data.getUint8(box.payloadOffset - box.offset);

    int baseTimescale = 1000;
    int totalDuration = 0;

    if (version == 0) {
      baseTimescale = data.getUint32(box.payloadOffset - box.offset + 12);
    } else {
      baseTimescale = data.getUint32(box.payloadOffset - box.offset + 20);
    }

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null) {
        final mdhd = _findBox(m.bytes, [trak], 'mdhd');
        if (mdhd != null) {
          final mData = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + mdhd.payloadOffset, mdhd.payloadSize);
          final v = mData.getUint8(0);
          int tScale = 1000;
          int dur = 0;
          if (v == 0) {
            tScale = mData.getUint32(12);
            dur = mData.getUint32(16);
          } else {
            tScale = mData.getUint32(20);
            dur = mData.getUint64(24);
          }
          final normDur = (tScale > 0) ? (dur * (baseTimescale / tScale)).round() : dur;
          totalDuration += normDur;
        }
      }
    }

    if (version == 0) {
      data.setUint32(box.payloadOffset - box.offset + 16, totalDuration);
    } else {
      data.setUint64(box.payloadOffset - box.offset + 24, totalDuration);
    }
    return bytes;
  }

  static Uint8List? _updateMinf(
    Uint8List mdiaBytes,
    Mp4Box minfBox,
    List<Mp4FileMeta> metas,
    int newMdatPayloadOffset,
    String handlerType,
  ) {
    try {
      final minfBytes = mdiaBytes.sublist(minfBox.payloadOffset, minfBox.payloadOffset + minfBox.payloadSize);
      final minfBoxes = _parseBoxes(minfBytes);
      final builder = BytesBuilder();

      for (final box in minfBoxes) {
        if (box.type == 'stbl') {
          final updatedStbl = _updateStbl(minfBytes, box, metas, newMdatPayloadOffset, handlerType);
          builder.add(updatedStbl ?? minfBytes.sublist(box.offset, box.offset + box.totalSize));
        } else {
          builder.add(minfBytes.sublist(box.offset, box.offset + box.totalSize));
        }
      }

      final payload = builder.takeBytes();
      final header = ByteData(8);
      header.setUint32(0, payload.length + 8);
      header.setUint8(4, 0x6D);
      header.setUint8(5, 0x69);
      header.setUint8(6, 0x6E);
      header.setUint8(7, 0x66);

      final result = BytesBuilder();
      result.add(header.buffer.asUint8List());
      result.add(payload);
      return result.takeBytes();
    } catch (e) {
      return null;
    }
  }

  static Uint8List? _updateStbl(
    Uint8List minfBytes,
    Mp4Box stblBox,
    List<Mp4FileMeta> metas,
    int newMdatPayloadOffset,
    String handlerType,
  ) {
    try {
      final stblBytes = minfBytes.sublist(stblBox.payloadOffset, stblBox.payloadOffset + stblBox.payloadSize);
      final stblBoxes = _parseBoxes(stblBytes);
      final builder = BytesBuilder();

      bool chunkOffsetAdded = false;
      bool stssAdded = false;

      final newChunkOffsetBox = _mergeChunkOffsets(metas, newMdatPayloadOffset, handlerType);
      final newStssBox = _mergeStss(metas, handlerType);

      for (final box in stblBoxes) {
        if (box.type == 'stts') {
          builder.add(_mergeStts(metas, handlerType));
        } else if (box.type == 'stsz') {
          builder.add(_mergeStsz(metas, handlerType));
        } else if (box.type == 'stsc') {
          builder.add(_mergeStsc(metas, handlerType));
        } else if (box.type == 'stco' || box.type == 'co64') {
          if (!chunkOffsetAdded) {
            builder.add(newChunkOffsetBox);
            chunkOffsetAdded = true;
          }
        } else if (box.type == 'stss') {
          if (!stssAdded) {
            if (newStssBox != null) {
              builder.add(newStssBox);
            }
            stssAdded = true;
          }
        } else {
          builder.add(stblBytes.sublist(box.offset, box.offset + box.totalSize));
        }
      }

      if (!chunkOffsetAdded) {
        builder.add(newChunkOffsetBox);
      }

      if (!stssAdded && newStssBox != null) {
        builder.add(newStssBox);
      }

      final payload = builder.takeBytes();
      final header = ByteData(8);
      header.setUint32(0, payload.length + 8);
      header.setUint8(4, 0x73);
      header.setUint8(5, 0x74);
      header.setUint8(6, 0x62);
      header.setUint8(7, 0x6C);

      final result = BytesBuilder();
      result.add(header.buffer.asUint8List());
      result.add(payload);
      return result.takeBytes();
    } catch (e) {
      return null;
    }
  }

  static Uint8List _mergeStts(List<Mp4FileMeta> metas, String handlerType) {
    final entryBytes = BytesBuilder();
    int totalEntries = 0;

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null) {
        final stts = _findBox(m.bytes, [trak], 'stts');
        if (stts != null) {
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stts.payloadOffset, stts.payloadSize);
          final count = data.getUint32(4);
          totalEntries += count;
          entryBytes.add(m.bytes.sublist(stts.payloadOffset + 8, stts.payloadOffset + 8 + count * 8));
        }
      }
    }

    final payload = BytesBuilder();
    final headerData = ByteData(8);
    headerData.setUint32(0, 0);
    headerData.setUint32(4, totalEntries);
    payload.add(headerData.buffer.asUint8List());
    payload.add(entryBytes.takeBytes());

    final pBytes = payload.takeBytes();
    final boxHeader = ByteData(8);
    boxHeader.setUint32(0, pBytes.length + 8);
    boxHeader.setUint8(4, 0x73);
    boxHeader.setUint8(5, 0x74);
    boxHeader.setUint8(6, 0x74);
    boxHeader.setUint8(7, 0x73);

    final res = BytesBuilder();
    res.add(boxHeader.buffer.asUint8List());
    res.add(pBytes);
    return res.takeBytes();
  }

  static Uint8List _mergeStsz(List<Mp4FileMeta> metas, String handlerType) {
    final sizeBytes = BytesBuilder();
    int totalSamples = 0;

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null) {
        final stsz = _findBox(m.bytes, [trak], 'stsz');
        if (stsz != null) {
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stsz.payloadOffset, stsz.payloadSize);
          final sampleSize = data.getUint32(4);
          final count = data.getUint32(8);
          totalSamples += count;
          if (sampleSize == 0) {
            sizeBytes.add(m.bytes.sublist(stsz.payloadOffset + 12, stsz.payloadOffset + 12 + count * 4));
          } else {
            final temp = ByteData(count * 4);
            for (var i = 0; i < count; i++) {
              temp.setUint32(i * 4, sampleSize);
            }
            sizeBytes.add(temp.buffer.asUint8List());
          }
        }
      }
    }

    final payload = BytesBuilder();
    final headerData = ByteData(12);
    headerData.setUint32(0, 0);
    headerData.setUint32(4, 0);
    headerData.setUint32(8, totalSamples);
    payload.add(headerData.buffer.asUint8List());
    payload.add(sizeBytes.takeBytes());

    final pBytes = payload.takeBytes();
    final boxHeader = ByteData(8);
    boxHeader.setUint32(0, pBytes.length + 8);
    boxHeader.setUint8(4, 0x73);
    boxHeader.setUint8(5, 0x74);
    boxHeader.setUint8(6, 0x73);
    boxHeader.setUint8(7, 0x7A);

    final res = BytesBuilder();
    res.add(boxHeader.buffer.asUint8List());
    res.add(pBytes);
    return res.takeBytes();
  }

  static int _getTrackChunkCount(Mp4FileMeta m, String handlerType) {
    final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
    if (trak != null) {
      final stco = _findBox(m.bytes, [trak], 'stco');
      if (stco != null) {
        final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stco.payloadOffset, stco.payloadSize);
        return data.getUint32(4);
      }
      final co64 = _findBox(m.bytes, [trak], 'co64');
      if (co64 != null) {
        final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + co64.payloadOffset, co64.payloadSize);
        return data.getUint32(4);
      }
    }
    return 0;
  }

  static int _getTrackSampleCount(Mp4FileMeta m, String handlerType) {
    final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
    if (trak != null) {
      final stsz = _findBox(m.bytes, [trak], 'stsz');
      if (stsz != null) {
        final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stsz.payloadOffset, stsz.payloadSize);
        return data.getUint32(8);
      }
    }
    return 0;
  }

  static Uint8List _mergeStsc(List<Mp4FileMeta> metas, String handlerType) {
    final entryBytes = BytesBuilder();
    int totalEntries = 0;
    int currentChunkOffset = 0;

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null) {
        final stsc = _findBox(m.bytes, [trak], 'stsc');
        if (stsc != null) {
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stsc.payloadOffset, stsc.payloadSize);
          final count = data.getUint32(4);
          totalEntries += count;

          for (var i = 0; i < count; i++) {
            final offset = stsc.payloadOffset + 8 + i * 12;
            final firstChunk = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + offset, 4).getUint32(0);
            final samplesPerChunk = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + offset + 4, 4).getUint32(0);
            final sampleDescIndex = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + offset + 8, 4).getUint32(0);

            final entry = ByteData(12);
            entry.setUint32(0, (firstChunk - 1) + currentChunkOffset + 1);
            entry.setUint32(4, samplesPerChunk);
            entry.setUint32(8, sampleDescIndex);
            entryBytes.add(entry.buffer.asUint8List());
          }
        }
      }

      currentChunkOffset += _getTrackChunkCount(m, handlerType);
    }

    final payload = BytesBuilder();
    final headerData = ByteData(8);
    headerData.setUint32(0, 0);
    headerData.setUint32(4, totalEntries);
    payload.add(headerData.buffer.asUint8List());
    payload.add(entryBytes.takeBytes());

    final pBytes = payload.takeBytes();
    final boxHeader = ByteData(8);
    boxHeader.setUint32(0, pBytes.length + 8);
    boxHeader.setUint8(4, 0x73);
    boxHeader.setUint8(5, 0x74);
    boxHeader.setUint8(6, 0x73);
    boxHeader.setUint8(7, 0x63);

    final res = BytesBuilder();
    res.add(boxHeader.buffer.asUint8List());
    res.add(pBytes);
    return res.takeBytes();
  }

  static Uint8List _mergeChunkOffsets(List<Mp4FileMeta> metas, int newMdatPayloadOffset, String handlerType) {
    final allOffsets = <int>[];
    int accumulatedMdatOffset = newMdatPayloadOffset;
    bool useCo64 = false;

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      final originalMdatPayloadOffset = m.mdatBox.payloadOffset;

      if (trak != null) {
        final stco = _findBox(m.bytes, [trak], 'stco');
        final co64 = _findBox(m.bytes, [trak], 'co64');

        if (co64 != null) {
          useCo64 = true;
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + co64.payloadOffset, co64.payloadSize);
          final count = data.getUint32(4);
          for (var i = 0; i < count; i++) {
            final oldChunkOffset = data.getUint64(8 + i * 8);
            final relativeOffsetInMdat = oldChunkOffset - originalMdatPayloadOffset;
            final newChunkOffset = accumulatedMdatOffset + relativeOffsetInMdat;
            allOffsets.add(newChunkOffset);
            if (newChunkOffset > 0xFFFFFFFF) useCo64 = true;
          }
        } else if (stco != null) {
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stco.payloadOffset, stco.payloadSize);
          final count = data.getUint32(4);
          for (var i = 0; i < count; i++) {
            final oldChunkOffset = data.getUint32(8 + i * 4);
            final relativeOffsetInMdat = oldChunkOffset - originalMdatPayloadOffset;
            final newChunkOffset = accumulatedMdatOffset + relativeOffsetInMdat;
            allOffsets.add(newChunkOffset);
            if (newChunkOffset > 0xFFFFFFFF) useCo64 = true;
          }
        }
      }
      accumulatedMdatOffset += m.mdatBox.payloadSize;
    }

    if (useCo64) {
      final entryBytes = BytesBuilder();
      for (final off in allOffsets) {
        final b = ByteData(8);
        b.setUint64(0, off);
        entryBytes.add(b.buffer.asUint8List());
      }
      final payload = BytesBuilder();
      final headerData = ByteData(8);
      headerData.setUint32(0, 0);
      headerData.setUint32(4, allOffsets.length);
      payload.add(headerData.buffer.asUint8List());
      payload.add(entryBytes.takeBytes());

      final pBytes = payload.takeBytes();
      final boxHeader = ByteData(8);
      boxHeader.setUint32(0, pBytes.length + 8);
      boxHeader.setUint8(4, 0x63); // 'c'
      boxHeader.setUint8(5, 0x6F); // 'o'
      boxHeader.setUint8(6, 0x36); // '6'
      boxHeader.setUint8(7, 0x34); // '4'

      final res = BytesBuilder();
      res.add(boxHeader.buffer.asUint8List());
      res.add(pBytes);
      return res.takeBytes();
    } else {
      final entryBytes = BytesBuilder();
      for (final off in allOffsets) {
        final b = ByteData(4);
        b.setUint32(0, off);
        entryBytes.add(b.buffer.asUint8List());
      }
      final payload = BytesBuilder();
      final headerData = ByteData(8);
      headerData.setUint32(0, 0);
      headerData.setUint32(4, allOffsets.length);
      payload.add(headerData.buffer.asUint8List());
      payload.add(entryBytes.takeBytes());

      final pBytes = payload.takeBytes();
      final boxHeader = ByteData(8);
      boxHeader.setUint32(0, pBytes.length + 8);
      boxHeader.setUint8(4, 0x73); // 's'
      boxHeader.setUint8(5, 0x74); // 't'
      boxHeader.setUint8(6, 0x63); // 'c'
      boxHeader.setUint8(7, 0x6F); // 'o'

      final res = BytesBuilder();
      res.add(boxHeader.buffer.asUint8List());
      res.add(pBytes);
      return res.takeBytes();
    }
  }

  static Uint8List? _mergeStss(List<Mp4FileMeta> metas, String handlerType) {
    final allKeyframes = <int>[];
    int currentSampleOffset = 0;
    bool hasAnyStss = false;

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      final clipSampleCount = _getTrackSampleCount(m, handlerType);

      if (trak != null) {
        final stss = _findBox(m.bytes, [trak], 'stss');
        if (stss != null) {
          hasAnyStss = true;
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stss.payloadOffset, stss.payloadSize);
          final count = data.getUint32(4);
          for (var i = 0; i < count; i++) {
            final sampleNum = data.getUint32(8 + i * 4);
            allKeyframes.add(sampleNum + currentSampleOffset);
          }
        } else if (handlerType == 'vide') {
          // No stss -> all samples are keyframes
          for (var s = 1; s <= clipSampleCount; s++) {
            allKeyframes.add(s + currentSampleOffset);
          }
        }
      }

      currentSampleOffset += clipSampleCount;
    }

    if (!hasAnyStss && handlerType != 'vide') return null;
    if (allKeyframes.isEmpty) return null;

    final entryBytes = BytesBuilder();
    for (final k in allKeyframes) {
      final b = ByteData(4);
      b.setUint32(0, k);
      entryBytes.add(b.buffer.asUint8List());
    }

    final payload = BytesBuilder();
    final headerData = ByteData(8);
    headerData.setUint32(0, 0);
    headerData.setUint32(4, allKeyframes.length);
    payload.add(headerData.buffer.asUint8List());
    payload.add(entryBytes.takeBytes());

    final pBytes = payload.takeBytes();
    final boxHeader = ByteData(8);
    boxHeader.setUint32(0, pBytes.length + 8);
    boxHeader.setUint8(4, 0x73);
    boxHeader.setUint8(5, 0x74);
    boxHeader.setUint8(6, 0x73);
    boxHeader.setUint8(7, 0x73);

    final res = BytesBuilder();
    res.add(boxHeader.buffer.asUint8List());
    res.add(pBytes);
    return res.takeBytes();
  }
}
