import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Avatar,
  PageContent,
  PageHeader,
  PageShell,
  StatusBadge,
  TableCard,
} from '../../components/ui/AdminUI';
import { NannyService, NannyRow } from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { useAuthStore } from '../../hooks/useAuth';

/**
 * Intro-video review queue. Previously the only way to review a nanny's intro
 * video was to open each nanny individually — there was no way to discover which
 * nannies had a pending video. This wires NannyService.listPendingVideos() into
 * a real queue with inline approve / request-re-record actions.
 */
export default function VerifyVideos() {
  const [items, setItems] = useState<NannyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const { user } = useAuthStore();

  const load = () => {
    setLoading(true);
    setLoadError(null);
    NannyService.listPendingVideos()
      .then(setItems)
      .catch((e) => setLoadError((e as Error).message || 'Failed to load pending videos'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  const review = async (n: NannyRow, status: 'approved' | 'rejected') => {
    let reason: string | undefined;
    if (status === 'rejected') {
      reason = window.prompt('Reason (visible to the nanny — prompts a re-record):') ?? undefined;
      if (!reason) return;
    }
    setBusyId(n.id);
    setActionError(null);
    try {
      await NannyService.reviewVideo(n.id, status, user?.uid ?? 'unknown', reason);
      // No longer pending — drop it from the queue.
      setItems((prev) => prev.filter((x) => x.id !== n.id));
    } catch (e) {
      setActionError((e as Error).message || 'Video review failed');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <PageShell>
      <PageHeader
        title="Review intro videos"
        subtitle={`${items.length} pending · Approve or request a re-record`}
      />
      <PageContent>
        {actionError && (
          <div className="px-3 py-2 text-[10px] font-bold text-rose-dark">{actionError}</div>
        )}
        <TableCard title="Pending intro videos">
          {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
          {!loading && loadError && (
            <div className="px-3 py-4 text-[10px] font-bold text-rose-dark">{loadError}</div>
          )}
          {!loading && !loadError && items.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">
              All caught up — no pending videos.
            </div>
          )}
          {items.map((n) => (
            <div key={n.id} className="px-3 py-3 border-b border-[#F0F2FA] last:border-0">
              <div className="flex items-center gap-3">
                <Avatar letter={initials(n.fullName)} gradient={gradientFor(n.id)} />
                <div className="flex-1 min-w-0">
                  <div className="text-[10.5px] font-extrabold text-navy">{n.fullName}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0]">
                    {n.nationality} · {n.city}
                  </div>
                </div>
                <StatusBadge variant="verify">Video pending</StatusBadge>
                <Link
                  to={`/nannies/${n.id}`}
                  className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1"
                >
                  Profile →
                </Link>
              </div>
              {n.introVideoUrl ? (
                <video
                  src={n.introVideoUrl}
                  controls
                  preload="metadata"
                  className="w-full max-h-72 rounded-lg bg-black mt-2"
                />
              ) : (
                <div className="text-[9px] text-[#8090B0] mt-2">No video URL on record.</div>
              )}
              <div className="flex gap-1.5 mt-2">
                <button
                  type="button"
                  className="qa-btn qa-g"
                  disabled={busyId === n.id}
                  onClick={() => review(n, 'approved')}
                >
                  Approve ✓
                </button>
                <button
                  type="button"
                  className="qa-btn qa-r"
                  disabled={busyId === n.id}
                  onClick={() => review(n, 'rejected')}
                >
                  Request re-record ✗
                </button>
              </div>
            </div>
          ))}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
