import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Avatar,
  DetailCard,
  Field,
  FieldGrid,
  PageContent,
  PageHeader,
  PageShell,
  QaLink,
  StatusBadge,
  PageLoader,
} from '../../components/ui/AdminUI';
import { NannyService, NannyRow, ChatService, ChatThreadRow } from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { useAuthStore } from '../../hooks/useAuth';
import { NannyProfileView, Section } from '../../components/nanny/NannyProfileView';
import { ConversationsPanel } from '../../components/chat/ConversationsPanel';
import { useLocale } from '../../context/LocaleContext';
import { nannyProfileStatusLabel } from '../../utils/nannyLabels';

export default function NannyDetail() {
  const { t } = useLocale();
  const { id } = useParams();
  const nav = useNavigate();
  const [nanny, setNanny] = useState<NannyRow | null>(null);
  const [threads, setThreads] = useState<ChatThreadRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<Partial<NannyRow>>({});
  const [busy, setBusy] = useState(false);
  const { user } = useAuthStore();

  // Loads the nanny and merges the sensitive KYC URLs from the private
  // nannies/{id}/documents subcollection (C5) into each document for preview.
  const fetchMerged = async (nannyId: string): Promise<NannyRow | null> => {
    const n = await NannyService.get(nannyId);
    if (!n) return null;
    const urls = await NannyService.getDocumentUrls(nannyId).catch(
      () => ({}) as Record<string, string>,
    );
    return {
      ...n,
      documents: (n.documents ?? []).map((d) => ({ ...d, url: d.url ?? urls[d.type] })),
    };
  };

  useEffect(() => {
    if (!id) return;
    fetchMerged(id)
      .then((n) => {
        setNanny(n);
        if (n) setForm({ fullName: n.fullName, nationality: n.nationality, city: n.city });
      })
      .finally(() => setLoading(false));
    // Guard the fetch — an unhandled rejection here previously bubbled up; a
    // thread-load failure should just leave the conversations panel empty.
    ChatService.listThreadsForNanny(id).then(setThreads).catch(() => setThreads([]));
  }, [id]);

  if (loading) {
    return (
      <PageShell>
        <PageContent>
          <PageLoader />
        </PageContent>
      </PageShell>
    );
  }

  if (!nanny) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">{t('common.notFound')}</div>
        </PageContent>
      </PageShell>
    );
  }

  const save = async () => {
    setBusy(true);
    try {
      await NannyService.update(nanny.id, form);
      setEditing(false);
      const fresh = await fetchMerged(nanny.id);
      if (fresh) setNanny(fresh);
    } catch (e) {
      alert((e as Error).message || t('nannies.saveFailed'));
    } finally {
      setBusy(false);
    }
  };

  const approve = async () => {
    setBusy(true);
    try {
      await NannyService.approve(nanny.id, user?.uid ?? 'unknown');
      const fresh = await fetchMerged(nanny.id);
      if (fresh) setNanny(fresh);
    } catch (e) {
      alert((e as Error).message || t('nannies.approveFailed'));
    } finally {
      setBusy(false);
    }
  };

  const reject = async () => {
    const reason = window.prompt(t('nannies.rejectPrompt'));
    if (!reason) return;
    setBusy(true);
    try {
      await NannyService.reject(nanny.id, reason, user?.uid ?? 'unknown');
      nav('/nannies');
    } catch (e) {
      alert((e as Error).message || t('nannies.rejectFailed'));
      setBusy(false);
    }
  };

  const toggleBlock = async () => {
    setBusy(true);
    try {
      if (nanny.blocked) {
        await NannyService.unblock(nanny.id);
      } else {
        await NannyService.block(nanny.id);
      }
      const fresh = await fetchMerged(nanny.id);
      if (fresh) setNanny(fresh);
    } catch (e) {
      alert((e as Error).message || t('nannies.blockFailed'));
    } finally {
      setBusy(false);
    }
  };

  const reviewVideo = async (status: 'approved' | 'rejected') => {
    let reason: string | undefined;
    if (status === 'rejected') {
      reason = window.prompt(t('nannies.videoRejectPrompt')) ?? undefined;
      if (!reason) return;
    }
    setBusy(true);
    try {
      await NannyService.reviewVideo(nanny.id, status, user?.uid ?? 'unknown', reason);
      const fresh = await fetchMerged(nanny.id);
      if (fresh) setNanny(fresh);
    } catch (e) {
      alert((e as Error).message || t('nannies.videoReviewFailed'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <PageShell>
      <PageHeader
        title={nanny.fullName || t('nannies.profileFallback')}
        subtitle={t('nannies.profileHash', { id: nanny.id })}
        actions={
          <>
            <QaLink to="/nannies" variant="n">
              {t('nannies.allNanniesLink')}
            </QaLink>
            {nanny.status !== 'approved' && (
              <button type="button" className="qa-btn qa-g" onClick={approve} disabled={busy}>
                {t('common.approve')}
              </button>
            )}
            {nanny.status !== 'rejected' && (
              <button type="button" className="qa-btn qa-r" onClick={reject} disabled={busy}>
                {t('common.reject')}
              </button>
            )}
            <button
              type="button"
              className={`qa-btn ${nanny.blocked ? 'qa-g' : 'qa-r'}`}
              onClick={toggleBlock}
              disabled={busy}
            >
              {nanny.blocked ? t('common.unblock') : t('common.block')}
            </button>
          </>
        }
      />
      <PageContent>
        <DetailCard>
          <div className="flex items-center gap-4">
            {nanny.photoUrls && nanny.photoUrls[0] ? (
              <img
                src={nanny.photoUrls[0]}
                alt={nanny.fullName}
                className="w-[52px] h-[52px] rounded-xl object-cover flex-shrink-0 bg-[#F4F5FC]"
              />
            ) : (
              <Avatar letter={initials(nanny.fullName)} gradient={gradientFor(nanny.id)} />
            )}
            <div className="flex-1">
              {editing ? (
                <input
                  value={form.fullName ?? ''}
                  onChange={(e) => setForm({ ...form, fullName: e.target.value })}
                  className="admin-card text-[12px] font-black text-navy px-2 py-1 border-[#EBEEF8] focus:outline-none w-full max-w-xs"
                />
              ) : (
                <div className="text-[13px] font-black text-navy">{nanny.fullName}</div>
              )}
              <div className="text-[9px] font-semibold text-[#8090B0] mt-0.5">
                {nanny.nationality} · {nanny.city} {nanny.experienceYears ? `· ${t('nannies.yrsExp', { count: nanny.experienceYears })}` : ''}
              </div>
              <div className="mt-2 flex gap-1.5 flex-wrap">
                <StatusBadge variant={nanny.isVerified ? 'verified' : 'verify'}>
                  {nanny.isVerified ? t('nannies.kafiVerified') : t('nannies.awaitingVerification')}
                </StatusBadge>
                <StatusBadge variant={nanny.status === 'approved' ? 'active' : nanny.status === 'rejected' ? 'rejected' : 'pending'}>
                  {nannyProfileStatusLabel(nanny.status)}
                </StatusBadge>
                {nanny.blocked && <StatusBadge variant="rejected">{t('nannies.blockedBadge')}</StatusBadge>}
              </div>
            </div>
            <button
              type="button"
              className={`qa-btn ${editing ? 'qa-g' : 'qa-n'}`}
              onClick={editing ? save : () => setEditing(true)}
              disabled={busy}
            >
              {editing ? t('common.save') : t('common.edit')}
            </button>
          </div>

          <FieldGrid>
            {editing ? (
              <>
                <div>
                  <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide">{t('nannies.nationality')}</div>
                  <input
                    value={form.nationality ?? ''}
                    onChange={(e) => setForm({ ...form, nationality: e.target.value })}
                    className="admin-card text-[10.5px] font-extrabold text-navy px-2 py-1 border-[#EBEEF8] focus:outline-none w-full"
                  />
                </div>
                <div>
                  <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide">{t('nannies.city')}</div>
                  <input
                    value={form.city ?? ''}
                    onChange={(e) => setForm({ ...form, city: e.target.value })}
                    className="admin-card text-[10.5px] font-extrabold text-navy px-2 py-1 border-[#EBEEF8] focus:outline-none w-full"
                  />
                </div>
              </>
            ) : (
              <>
                <Field label={t('nannies.nationality')} value={nanny.nationality || t('common.dash')} />
                <Field label={t('nannies.city')} value={nanny.city || t('common.dash')} />
                <Field label={t('nannies.experience')} value={nanny.experienceYears ? t('nannies.yrs', { count: nanny.experienceYears }) : t('common.dash')} />
                <Field label={t('nannies.profileScore')} value={`${nanny.profileScore ?? 0}%`} />
                <Field label={t('common.status')} value={nannyProfileStatusLabel(nanny.status)} />
                <Field label={t('nannies.verifiedField')} value={nanny.isVerified ? t('common.yes') : t('common.no')} />
              </>
            )}
          </FieldGrid>
        </DetailCard>

        <NannyProfileView nanny={nanny} onReviewVideo={reviewVideo} videoBusy={busy} />

        <Section title={t('nannies.conversationsWithFamilies', { count: threads.length })}>
          <ConversationsPanel threads={threads} counterpart="family" />
        </Section>
      </PageContent>
    </PageShell>
  );
}
