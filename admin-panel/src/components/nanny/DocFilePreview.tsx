/**
 * Multi-format document preview for admin document verification.
 *
 * Nanny documents (passport, visa, EID, certificates, …) may be uploaded as
 * images, PDFs, videos or other formats. Firebase download URLs keep the file
 * extension before the `?alt=media&token=…` query, so we can infer how to
 * render each file.
 */
import { useLocale } from '../../context/LocaleContext';

export type DocKind = 'image' | 'video' | 'pdf' | 'other';

const IMAGE_EXT = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'gif', 'bmp'];
const VIDEO_EXT = ['mp4', 'mov', 'webm', 'm4v', 'avi', 'mkv', '3gp'];

export function docKind(url?: string | null): DocKind {
  if (!url) return 'other';
  const clean = url.split('?')[0].toLowerCase();
  const ext = clean.substring(clean.lastIndexOf('.') + 1);
  if (IMAGE_EXT.includes(ext)) return 'image';
  if (VIDEO_EXT.includes(ext)) return 'video';
  if (ext === 'pdf') return 'pdf';
  return 'other';
}

/** Small type-aware thumbnail used in the verification queue list. */
export function DocThumb({ url, label }: { url?: string | null; label: string }) {
  const { t } = useLocale();
  if (!url) {
    return (
      <div className="w-16 h-12 rounded-md bg-[#F4F5FC] flex items-center justify-center text-[8px] font-bold text-[#A0ADC8] flex-shrink-0">
        {t('common.none')}
      </div>
    );
  }
  const kind = docKind(url);
  const wrap = 'w-16 h-12 rounded-md bg-[#F4F5FC] object-cover flex-shrink-0';
  return (
    <a href={url} target="_blank" rel="noreferrer" className="flex-shrink-0" title={label}>
      {kind === 'image' ? (
        <img src={url} alt={label} className={wrap} loading="lazy" />
      ) : kind === 'video' ? (
        <video src={url} className={wrap} muted preload="metadata" />
      ) : (
        <div className={`${wrap} flex items-center justify-center text-[8px] font-extrabold text-purple`}>
          {kind === 'pdf' ? t('common.pdf') : t('common.file')}
        </div>
      )}
    </a>
  );
}

/** Full inline viewer used on the nanny profile / detail view. */
export function DocViewer({ url, label }: { url?: string | null; label: string }) {
  const { t } = useLocale();
  if (!url) {
    return (
      <div className="w-full h-28 rounded-lg bg-[#F4F5FC] flex items-center justify-center text-[10px] font-bold text-[#A0ADC8]">
        {t('common.notUploaded')}
      </div>
    );
  }
  const kind = docKind(url);
  if (kind === 'image') {
    return (
      <a href={url} target="_blank" rel="noreferrer">
        <img
          src={url}
          alt={label}
          className="w-full max-h-72 object-contain rounded-lg bg-[#F4F5FC]"
          loading="lazy"
        />
      </a>
    );
  }
  if (kind === 'video') {
    return (
      <video src={url} controls preload="metadata" className="w-full max-h-72 rounded-lg bg-black" />
    );
  }
  if (kind === 'pdf') {
    return (
      <div className="flex flex-col gap-1">
        <iframe src={url} title={label} className="w-full h-72 rounded-lg border border-[#EBEEF8] bg-white" />
        <a href={url} target="_blank" rel="noreferrer" className="text-[9px] font-bold text-purple font-fredoka self-end">
          {t('common.openPdf')}
        </a>
      </div>
    );
  }
  return (
    <a
      href={url}
      target="_blank"
      rel="noreferrer"
      className="w-full h-24 rounded-lg border border-[#EBEEF8] bg-[#F4F5FC] flex flex-col items-center justify-center gap-1 text-[10px] font-bold text-purple"
    >
      <span className="text-lg">📄</span>
      {t('common.downloadFile')}
    </a>
  );
}
