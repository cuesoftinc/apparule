-- Images are private (system-design.md I-8): rows keep object keys and
-- the API signs a URL on each read. Older rows held public URLs.

SELECT set_config('app.bypass_rls', 'on', true);

ALTER TABLE request RENAME COLUMN post_thumb_url TO post_thumb_key;
UPDATE request SET post_thumb_key = '' WHERE post_thumb_key LIKE 'http%';

ALTER TABLE notification RENAME COLUMN thumb_url TO thumb_key;
UPDATE notification SET thumb_key = NULL WHERE thumb_key LIKE 'http%';

UPDATE report SET subject_preview = subject_preview - 'thumb_url' WHERE subject_preview ? 'thumb_url';
