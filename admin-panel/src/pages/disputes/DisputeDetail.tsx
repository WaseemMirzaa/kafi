import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
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
import { Section } from '../../components/nanny/NannyProfileView';
import { DocViewer } from '../../components/nanny/DocFilePreview';
import { MessageThread, ThreadMessage } from '../../components/chat/MessageThread';
import {
  DisputeService,
  DisputeRow,
  DisputeMessageRow,
  DisputeUserSnapshot,
} from '../../services/firestore';
import { useLocale } from '../../context/LocaleContext';
import { disputeStatusLabel, personTypeLabel } from '../../utils/nannyLabels';
import { t as translate, TranslationKey } from '../../locales/t';

const categoryLabelKeys: Record<DisputeRow['category'], TranslationKey> = {
  fraud: 'reports.category.fraud',
  abuse: 'reports.category.abuse',
  no_show: 'reports.category.no_show',
  payment: 'reports.category.payment',
  other: 'reports.category.other',
};

const statusVariant: Record<DisputeRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  dismissed: 'rejected',
};

function displayName(name: string | undefined, fallback: string): string {
  const trimmed = name?.trim();
  return trimmed ? trimmed : fallback;
}

function toThreadMessages(msgs: DisputeMessageRow[]): ThreadMessage[] {
  return msgs.map((m) => ({
    id: m.id,
    align: m.senderType === 'admin' ? 'right' : 'left',
    author: m.senderName ?? (m.senderType === 'admin' ? translate('chat.supportSender') : translate('chat.userSender')),
    content: m.content,
    timestamp: m.createdAt,
  }));
}

function profilePath(type: 'family' | 'nanny' | undefined, userId: string): string | null {
  if (!userId) return null;
  if (type === 'nanny') return `/nannies/${userId}`;
  if (type === 'family') return `/families/${userId}`;
  return null;
}

function snapshotLines(snap: DisputeUserSnapshot | undefined, t: (k: TranslationKey) => string): string {
  if (!snap) return t('common.dash');
  const parts: string[] = [];
  if (snap.phone) parts.push(snap.phone);
  if (snap.city) parts.push(snap.city);
  if (snap.nationality) parts.push(snap.nationality);
  if (snap.status) parts.push(snap.status);
  return parts.length ? parts.join(' · ') : t('common.dash');
}

export default function DisputeDetail() {
  const { t } = useLocale();
  const { id } = useParams();
  const [dispute, setDispute] = useState<DisputeRow | null>(null);
  const [messages, setMessages] = useState<DisputeMessageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);
  const [resolution, setResolution] = useState('');
  const [decision, setDecision] = useState<'resolved' | 'dismissed'>('resolved');
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  // Report details start expanded when evidence is present so attachments are
  // visible without an extra click; otherwise collapsed to keep chat first.
  const [detailsOpen, setDetailsOpen] = useState(false);

  // Live dispute doc + messages so family/nanny replies and (if another admin
  // resolves) status changes appear without a manual refresh.
  useEffect(() => {
    if (!id) return;
    setLoading(true);
    setError(null);
    let gotDoc = false;
    let gotMsgs = false;
    const markReady = () => {
      if (gotDoc && gotMsgs) setLoading(false);
    };
    const unsubDoc = DisputeService.watch(
      id,
      (d) => {
        setDispute(d);
        gotDoc = true;
        markReady();
        if (!d) setError(null);
        // Expand details once when evidence arrives so admins see IDs + files.
        if (d && ((d.attachments?.length ?? 0) > 0 || d.reporterSnapshot || d.reportedSnapshot)) {
          setDetailsOpen(true);
        }
      },
      (e) => {
        setError(e.message || t('reports.failedToLoadReport'));
        gotDoc = true;
        markReady();
      },
    );
    const unsubMsgs = DisputeService.watchMessages(
      id,
      (m) => {
        setMessages(m);
        gotMsgs = true;
        markReady();
      },
      (e) => {
        setError(e.message || t('reports.failedToLoadReport'));
        gotMsgs = true;
        markReady();
      },
    );
    return () => {
      unsubDoc();
      unsubMsgs();
    };
  }, [id, t]);

  if (loading) {
    return (
      <PageShell>
        <PageContent>
          <PageLoader />
        </PageContent>
      </PageShell>
    );
  }
  if (error && !dispute) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] font-bold text-rose-dark">{error}</div>
        </PageContent>
      </PageShell>
    );
  }
  if (!dispute) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">{t('common.notFound')}</div>
        </PageContent>
      </PageShell>
    );
  }

  const reporterLabel = displayName(dispute.reporterName, t('reports.reporter'));
  const reportedLabel = displayName(dispute.reportedName, t('reports.reportedUser'));
  const closed = dispute.status === 'resolved' || dispute.status === 'dismissed';
  const reporterLink = profilePath(dispute.reporterType, dispute.reporterId);
  const reportedLink = profilePath(dispute.reportedType, dispute.reportedUserId);
  const attachments = dispute.attachments ?? [];

  const send = async (text: string) => {
    setSending(true);
    setActionError(null);
    try {
      // Snapshot listeners refresh messages + status (investigating advance).
      await DisputeService.sendMessage(dispute.id, text);
    } catch (e) {
      setActionError((e as Error).message || t('reports.failedToSendReply'));
    } finally {
      setSending(false);
    }
  };

  const resolve = async () => {
    if (!resolution.trim()) return;
    setBusy(true);
    setActionError(null);
    try {
      await DisputeService.resolve(dispute.id, resolution.trim(), decision);
      setResolution('');
    } catch (e) {
      setActionError((e as Error).message || t('reports.failedToSubmitResolution'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <PageShell>
      <PageHeader
        title={t('reports.reportTitle', { category: t(categoryLabelKeys[dispute.category]) })}
        subtitle={`${reporterLabel} → ${reportedLabel} · ${dispute.createdAt.toLocaleDateString()}`}
        actions={
          <QaLink to="/reports" variant="n">
            {t('reports.allReportsLink')}
          </QaLink>
        }
      />
      <PageContent>
        <DetailCard>
          {/* Collapsed summary row — tap to expand the full details. */}
          <button
            type="button"
            className="w-full flex items-center gap-2 text-left"
            onClick={() => setDetailsOpen((v) => !v)}
            aria-expanded={detailsOpen}
          >
            <div className="text-[12px] font-black text-navy">{t(categoryLabelKeys[dispute.category])}</div>
            <StatusBadge variant={statusVariant[dispute.status]}>{disputeStatusLabel(dispute.status)}</StatusBadge>
            <div className="flex-1 min-w-0 text-[8.5px] font-semibold text-[#8090B0] truncate">
              {reporterLabel} → {reportedLabel} · {dispute.createdAt.toLocaleDateString()}
              {attachments.length > 0 ? ` · 📎 ${attachments.length}` : ''}
            </div>
            <span className="text-[9.5px] font-bold text-purple font-fredoka flex-shrink-0">
              {detailsOpen ? t('reports.hideDetails') : t('reports.viewDetails')}
            </span>
          </button>
          {detailsOpen && (
            <>
              <FieldGrid>
                <Field
                  label={t('reports.reporterField')}
                  value={`${reporterLabel}${dispute.reporterType ? ` (${personTypeLabel(dispute.reporterType)})` : ''}`}
                />
                <Field label={t('reports.reporterId')} value={dispute.reporterId || t('common.dash')} />
                <Field
                  label={t('reports.reportedUserField')}
                  value={`${reportedLabel}${dispute.reportedType ? ` (${personTypeLabel(dispute.reportedType)})` : ''}`}
                />
                <Field label={t('reports.reportedUserId')} value={dispute.reportedUserId || t('common.dash')} />
                <Field label={t('reports.reporterSnapshot')} value={snapshotLines(dispute.reporterSnapshot, t)} />
                <Field label={t('reports.reportedSnapshot')} value={snapshotLines(dispute.reportedSnapshot, t)} />
                <Field label={t('reports.category')} value={t(categoryLabelKeys[dispute.category])} />
                <Field
                  label={t('reports.relatedTrial')}
                  value={
                    dispute.relatedTrialId ? (
                      <Link to={`/trials/${dispute.relatedTrialId}`} className="text-purple font-bold no-underline">
                        {dispute.relatedTrialId}
                      </Link>
                    ) : (
                      t('common.dash')
                    )
                  }
                />
                <Field label={t('reports.filedOn')} value={dispute.createdAt.toLocaleDateString()} />
              </FieldGrid>
              <div className="flex flex-wrap gap-2 mt-2">
                {reporterLink && (
                  <Link to={reporterLink} className="text-[9px] font-bold text-purple font-fredoka no-underline">
                    {t('reports.viewReporterProfile')}
                  </Link>
                )}
                {reportedLink && (
                  <Link to={reportedLink} className="text-[9px] font-bold text-purple font-fredoka no-underline">
                    {t('reports.viewReportedProfile')}
                  </Link>
                )}
              </div>
              <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mt-3">{t('reports.description')}</div>
              <p className="text-[10.5px] font-semibold text-navy/80 leading-relaxed mt-0.5">{dispute.description}</p>
              {dispute.resolution && (
                <div className="mt-3 rounded-lg bg-green-pale px-3 py-2">
                  <div className="text-[8px] font-bold text-green-dark uppercase tracking-wide">{t('reports.resolutionField')}</div>
                  <p className="text-[10px] font-semibold text-navy/80 mt-0.5">{dispute.resolution}</p>
                </div>
              )}
            </>
          )}
        </DetailCard>

        {attachments.length > 0 && (
          <Section title={t('reports.attachments')}>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-2">
              {attachments.map((a) => (
                <div key={a.id || a.url} className="min-w-0">
                  <div className="text-[8.5px] font-bold text-[#8090B0] truncate mb-1" title={a.name}>
                    {a.name || t('reports.attachment')}
                    {a.contentType ? ` · ${a.contentType}` : ''}
                  </div>
                  <DocViewer url={a.url} label={a.name || t('reports.attachment')} />
                </div>
              ))}
            </div>
          </Section>
        )}

        {actionError && (
          <div className="mx-2 mb-2 p-2 bg-rose-pale text-rose-dark text-[10px] font-bold rounded-lg">
            {actionError}
          </div>
        )}

        <Section title={t('reports.supportChat')}>
          <p className="text-[9px] font-semibold text-[#8090B0] mb-1">
            {t('reports.conversationWith', { name: reporterLabel === t('reports.reporter') ? t('reports.theReportingUser') : reporterLabel })}
          </p>
          <MessageThread
            messages={toThreadMessages(messages)}
            emptyText={t('common.noMessagesYet')}
            onSend={closed ? undefined : send}
            sending={sending}
            placeholder={t('common.replyToUser')}
          />
          {closed && (
            <div className="text-[9px] font-semibold text-[#8090B0] mt-2">
              {t('reports.reportStatusClosed', { status: disputeStatusLabel(dispute.status) })}
            </div>
          )}
        </Section>

        {!closed && (
          <Section title={t('reports.resolveReport')}>
            <div className="flex gap-1.5 mt-2 mb-2">
              <button
                type="button"
                className={`qa-btn ${decision === 'resolved' ? 'qa-g' : 'qa-n'}`}
                onClick={() => setDecision('resolved')}
              >
                {t('reports.resolved2')}
              </button>
              <button
                type="button"
                className={`qa-btn ${decision === 'dismissed' ? 'qa-r' : 'qa-n'}`}
                onClick={() => setDecision('dismissed')}
              >
                {t('reports.dismissed')}
              </button>
            </div>
            <textarea
              rows={3}
              value={resolution}
              onChange={(e) => setResolution(e.target.value)}
              placeholder={t('reports.resolutionPlaceholder')}
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none resize-none"
            />
            <div className="flex justify-end mt-2">
              <button type="button" className="qa-btn qa-r" onClick={resolve} disabled={!resolution.trim() || busy}>
                {t('reports.submitResolution')}
              </button>
            </div>
          </Section>
        )}
      </PageContent>
    </PageShell>
  );
}
