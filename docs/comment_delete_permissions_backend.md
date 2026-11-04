# Comment delete permissions — backend contract

Mobile app UI now hides the delete icon unless the user is the **comment author** or the **video owner**.  
**Backend must still enforce the same rules.** UI alone is not enough.

## Rules

1. Authenticated user required for `DELETE /app/comments/:commentId`.
2. Allow delete only if **either**:
   - `comment.userId === currentUser.id` (comment author), **or**
   - `video.userId === currentUser.id` where `video` is the comment’s video (video owner).
3. Otherwise respond **`403 Forbidden`** (do not delete).
4. Never delete based on client-only flags.

## Suggested server check (pseudo)

```
comment = db.comments.findById(commentId)
if (!comment) return 404

video = db.videos.findById(comment.videoId)
if (!video) return 404

me = auth.userId
isAuthor = comment.userId == me
isVideoOwner = video.userId == me

if (!isAuthor && !isVideoOwner) return 403

db.comments.delete(commentId)
return 200 { success: true }
```

## API

- `DELETE /app/comments/:commentId`
- Auth: session / bearer required
- Success: `200` with `{ "success": true }`
- Unauthorized role: `403` with `{ "success": false, "message": "Not allowed to delete this comment" }`

## Optional response field (recommended)

When listing comments (`GET /app/comments?videoId=`), include:

```json
{
  "canDelete": true
}
```

Set `canDelete` true only when the same author/owner rules pass for the requesting user.  
App already respects `canDelete` / `can_delete` if present.
