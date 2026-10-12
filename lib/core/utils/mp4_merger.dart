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
      if (metas.length < files.length) {
        debugPrint('Mp4Merger parsed only ${metas.length} of ${files.length} files. Cannot merge.');
        return null;
      }
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
        debugPrint('Moov merge returned null, merge failed');
        return null;
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
        } else if (box.type == 'edts') {
          // Skip edts box to allow the entire concatenated media timeline in mdia to play seamlessly without being clipped to clip 1's duration
          continue;
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

    int baseTimescale = 1000;
    if (metas.isNotEmpty) {
      final mvhd0 = _findBox(metas.first.bytes, metas.first.topBoxes, 'mvhd');
      if (mvhd0 != null) {
        final mvhdData = ByteData.view(metas.first.bytes.buffer, metas.first.bytes.offsetInBytes + mvhd0.payloadOffset, mvhd0.payloadSize);
        final v = mvhdData.getUint8(0);
        baseTimescale = (v == 0) ? mvhdData.getUint32(12) : mvhdData.getUint32(20);
        if (baseTimescale <= 0) baseTimescale = 1000;
      }
    }

    int totalDuration = 0;
    for (final m in metas) {
      int mTimescale = baseTimescale;
      final mvhd = _findBox(m.bytes, m.topBoxes, 'mvhd');
      if (mvhd != null) {
        final mvhdData = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + mvhd.payloadOffset, mvhd.payloadSize);
        final v = mvhdData.getUint8(0);
        mTimescale = (v == 0) ? mvhdData.getUint32(12) : mvhdData.getUint32(20);
        if (mTimescale <= 0) mTimescale = baseTimescale;
      }

      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null) {
        final tkhd = _findBox(m.bytes, [trak], 'tkhd');
        if (tkhd != null) {
          final tData = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + tkhd.payloadOffset, tkhd.payloadSize);
          final v = tData.getUint8(0);
          final dur = (v == 0) ? tData.getUint32(20) : tData.getUint64(28);
          final normDur = (mTimescale > 0) ? (dur * (baseTimescale / mTimescale)).round() : dur;
          totalDuration += normDur;
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
      bool cttsAdded = false;
      bool stsdAdded = false;

      final newChunkOffsetBox = _mergeChunkOffsets(metas, newMdatPayloadOffset, handlerType);
      final newStssBox = _mergeStss(metas, handlerType);
      final newCttsBox = _mergeCtts(metas, handlerType);
      final stsdResult = _mergeStsd(metas, handlerType);
      final newStsdBox = stsdResult.boxBytes;
      final metaSampleDescMap = stsdResult.metaSampleDescMap;

      for (final box in stblBoxes) {
        if (box.type == 'stsd') {
          if (!stsdAdded) {
            if (newStsdBox != null && newStsdBox.isNotEmpty) {
              builder.add(newStsdBox);
            } else {
              builder.add(stblBytes.sublist(box.offset, box.offset + box.totalSize));
            }
            stsdAdded = true;
          }
        } else if (box.type == 'stts') {
          builder.add(_mergeStts(metas, handlerType));
        } else if (box.type == 'stsz') {
          builder.add(_mergeStsz(metas, handlerType));
        } else if (box.type == 'stsc') {
          builder.add(_mergeStsc(metas, handlerType, metaSampleDescMap));
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
        } else if (box.type == 'ctts') {
          if (!cttsAdded) {
            if (newCttsBox != null) {
              builder.add(newCttsBox);
            }
            cttsAdded = true;
          }
        } else {
          builder.add(stblBytes.sublist(box.offset, box.offset + box.totalSize));
        }
      }

      if (!stsdAdded && newStsdBox != null && newStsdBox.isNotEmpty) {
        builder.add(newStsdBox);
      }

      if (!chunkOffsetAdded) {
        builder.add(newChunkOffsetBox);
      }

      if (!stssAdded && newStssBox != null) {
        builder.add(newStssBox);
      }

      if (!cttsAdded && newCttsBox != null) {
        builder.add(newCttsBox);
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

  static Uint8List? _mergeCtts(List<Mp4FileMeta> metas, String handlerType) {
    bool hasAnyCtts = false;
    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null && _findBox(m.bytes, [trak], 'ctts') != null) {
        hasAnyCtts = true;
        break;
      }
    }
    if (!hasAnyCtts) return null;

    final entryBytes = BytesBuilder();
    int totalEntries = 0;
    int version = 0;

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      final clipSamples = _getTrackSampleCount(m, handlerType);
      if (trak != null) {
        final ctts = _findBox(m.bytes, [trak], 'ctts');
        if (ctts != null && ctts.payloadSize >= 8) {
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + ctts.payloadOffset, ctts.payloadSize);
          final v = data.getUint8(0);
          if (v == 1) version = 1;
          final count = data.getUint32(4);
          totalEntries += count;
          entryBytes.add(m.bytes.sublist(ctts.payloadOffset + 8, ctts.payloadOffset + 8 + count * 8));
        } else if (clipSamples > 0) {
          final b = ByteData(8);
          b.setUint32(0, clipSamples);
          b.setUint32(4, 0);
          entryBytes.add(b.buffer.asUint8List());
          totalEntries++;
        }
      }
    }

    if (totalEntries == 0) return null;

    final payload = BytesBuilder();
    final headerData = ByteData(8);
    headerData.setUint8(0, version);
    headerData.setUint32(4, totalEntries);
    payload.add(headerData.buffer.asUint8List());
    payload.add(entryBytes.takeBytes());

    final pBytes = payload.takeBytes();
    final boxHeader = ByteData(8);
    boxHeader.setUint32(0, pBytes.length + 8);
    boxHeader.setUint8(4, 0x63); // 'c'
    boxHeader.setUint8(5, 0x74); // 't'
    boxHeader.setUint8(6, 0x74); // 't'
    boxHeader.setUint8(7, 0x73); // 's'

    final res = BytesBuilder();
    res.add(boxHeader.buffer.asUint8List());
    res.add(pBytes);
    return res.takeBytes();
  }

  static Uint8List _mergeStts(List<Mp4FileMeta> metas, String handlerType) {
    final entryBytes = BytesBuilder();
    int totalEntries = 0;

    int baseTimescale = 1000;
    if (metas.isNotEmpty) {
      final trak0 = _findTrakByHandler(metas.first.bytes, metas.first.topBoxes, handlerType);
      if (trak0 != null) {
        final mdhd0 = _findBox(metas.first.bytes, [trak0], 'mdhd');
        if (mdhd0 != null) {
          final mData = ByteData.view(metas.first.bytes.buffer, metas.first.bytes.offsetInBytes + mdhd0.payloadOffset, mdhd0.payloadSize);
          final v = mData.getUint8(0);
          baseTimescale = (v == 0) ? mData.getUint32(12) : mData.getUint32(20);
          if (baseTimescale <= 0) baseTimescale = 1000;
        }
      }
    }

    for (final m in metas) {
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak != null) {
        int mTimescale = baseTimescale;
        final mdhd = _findBox(m.bytes, [trak], 'mdhd');
        if (mdhd != null) {
          final mData = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + mdhd.payloadOffset, mdhd.payloadSize);
          final v = mData.getUint8(0);
          mTimescale = (v == 0) ? mData.getUint32(12) : mData.getUint32(20);
          if (mTimescale <= 0) mTimescale = baseTimescale;
        }

        final stts = _findBox(m.bytes, [trak], 'stts');
        if (stts != null) {
          final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stts.payloadOffset, stts.payloadSize);
          final count = data.getUint32(4);
          totalEntries += count;
          if (mTimescale == baseTimescale) {
            entryBytes.add(m.bytes.sublist(stts.payloadOffset + 8, stts.payloadOffset + 8 + count * 8));
          } else {
            final scaleRatio = baseTimescale / mTimescale;
            for (var i = 0; i < count; i++) {
              final sCount = data.getUint32(8 + i * 8);
              final sDelta = data.getUint32(12 + i * 8);
              final newDelta = (sDelta * scaleRatio).round();
              final b = ByteData(8);
              b.setUint32(0, sCount);
              b.setUint32(4, newDelta);
              entryBytes.add(b.buffer.asUint8List());
            }
          }
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

  static Uint8List _mergeStsc(
    List<Mp4FileMeta> metas,
    String handlerType, [
    Map<int, Map<int, int>>? metaSampleDescMap,
  ]) {
    final entryBytes = BytesBuilder();
    int totalEntries = 0;
    int currentChunkOffset = 0;

    for (int mIdx = 0; mIdx < metas.length; mIdx++) {
      final m = metas[mIdx];
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

            final newSampleDescIndex = metaSampleDescMap?[mIdx]?[sampleDescIndex] ?? sampleDescIndex;

            final entry = ByteData(12);
            entry.setUint32(0, (firstChunk - 1) + currentChunkOffset + 1);
            entry.setUint32(4, samplesPerChunk);
            entry.setUint32(8, newSampleDescIndex);
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

        // Ensure the very first sample of each clip is always marked as a sync keyframe
        if (clipSampleCount > 0 && handlerType == 'vide') {
          final firstSample = 1 + currentSampleOffset;
          if (!allKeyframes.contains(firstSample)) {
            allKeyframes.add(firstSample);
          }
        }
      }

      currentSampleOffset += clipSampleCount;
    }

    if (!hasAnyStss && handlerType != 'vide') return null;
    if (allKeyframes.isEmpty) return null;

    allKeyframes.sort();

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

  static _StsdMergeResult _mergeStsd(List<Mp4FileMeta> metas, String handlerType) {
    final uniqueEntries = <Uint8List>[];
    final metaSampleDescMap = <int, Map<int, int>>{};

    for (int mIdx = 0; mIdx < metas.length; mIdx++) {
      final m = metas[mIdx];
      metaSampleDescMap[mIdx] = {};
      final trak = _findTrakByHandler(m.bytes, m.topBoxes, handlerType);
      if (trak == null) continue;

      final stsd = _findBox(m.bytes, [trak], 'stsd');
      if (stsd == null || stsd.payloadSize < 8) continue;

      final data = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + stsd.payloadOffset, stsd.payloadSize);
      final entryCount = data.getUint32(4);

      int currentEntryOffset = stsd.payloadOffset + 8;
      for (int eIdx = 1; eIdx <= entryCount; eIdx++) {
        if (currentEntryOffset + 8 > stsd.payloadOffset + stsd.payloadSize) break;
        final entrySize = ByteData.view(m.bytes.buffer, m.bytes.offsetInBytes + currentEntryOffset, 4).getUint32(0);
        if (entrySize < 8 || currentEntryOffset + entrySize > stsd.payloadOffset + stsd.payloadSize) break;

        final entryBytes = m.bytes.sublist(currentEntryOffset, currentEntryOffset + entrySize);
        currentEntryOffset += entrySize;

        int matchIdx = -1;
        for (int u = 0; u < uniqueEntries.length; u++) {
          if (_areByteListsEqual(uniqueEntries[u], entryBytes)) {
            matchIdx = u;
            break;
          }
        }

        if (matchIdx >= 0) {
          metaSampleDescMap[mIdx]![eIdx] = matchIdx + 1;
        } else {
          uniqueEntries.add(entryBytes);
          metaSampleDescMap[mIdx]![eIdx] = uniqueEntries.length;
        }
      }
    }

    if (uniqueEntries.isEmpty) {
      if (metas.isNotEmpty) {
        final trak0 = _findTrakByHandler(metas.first.bytes, metas.first.topBoxes, handlerType);
        if (trak0 != null) {
          final stsd0 = _findBox(metas.first.bytes, [trak0], 'stsd');
          if (stsd0 != null) {
            final raw = metas.first.bytes.sublist(stsd0.offset, stsd0.offset + stsd0.totalSize);
            return _StsdMergeResult(boxBytes: raw, metaSampleDescMap: {});
          }
        }
      }
      return _StsdMergeResult(boxBytes: null, metaSampleDescMap: {});
    }

    final payloadBuilder = BytesBuilder();
    final headerData = ByteData(8);
    headerData.setUint32(0, 0); // version=0, flags=0
    headerData.setUint32(4, uniqueEntries.length);
    payloadBuilder.add(headerData.buffer.asUint8List());

    for (final eb in uniqueEntries) {
      payloadBuilder.add(eb);
    }

    final pBytes = payloadBuilder.takeBytes();
    final boxHeader = ByteData(8);
    boxHeader.setUint32(0, pBytes.length + 8);
    boxHeader.setUint8(4, 0x73); // 's'
    boxHeader.setUint8(5, 0x74); // 't'
    boxHeader.setUint8(6, 0x73); // 's'
    boxHeader.setUint8(7, 0x64); // 'd'

    final res = BytesBuilder();
    res.add(boxHeader.buffer.asUint8List());
    res.add(pBytes);
    return _StsdMergeResult(
      boxBytes: res.takeBytes(),
      metaSampleDescMap: metaSampleDescMap,
    );
  }

  static bool _areByteListsEqual(Uint8List a, Uint8List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _StsdMergeResult {
  final Uint8List? boxBytes;
  final Map<int, Map<int, int>> metaSampleDescMap;

  _StsdMergeResult({
    required this.boxBytes,
    required this.metaSampleDescMap,
  });
}
