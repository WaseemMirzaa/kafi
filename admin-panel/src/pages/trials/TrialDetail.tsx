import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
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
import { Section } from '../../components/nanny/NannyProfileView';
import { MessageThread, ThreadMessage } from '../../components/chat/MessageThread';
import {
  TrialService,
  TrialAdminRow,
  NannyService,
  NannyRow,
  FamilyService,
  FamilyRow,
  JobPostService,
  JobPostRow,
  ChatService,
  ChatThreadRow,
  ChatMessageRow,
} from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import {
  trialStatusVariant,
  trialStatusLabel,
  fmtDate,
  jobTypeFullLabel,
  visaSponsorshipLabel,
  salaryRange,
  listOr,
} from '../../utils/nannyLabels';
import { trialDayNumber, trialCountdown, trialTotalAmount } from '../../utils/trials';
import { useLocale } from '../../context/LocaleContext';
import { t as translate, TranslationKey } from '../../locales/t';

const EVAL_ITEMS: { key: keyof NonNullable<TrialAdminRow['evaluation']>; labelKey: TranslationKey }[] = [
  { key: 'childInteractionAndPatience', labelKey: 'trials.eval.childInteraction' },
  { key: 'punctualityAndReliability', labelKey: 'trials.eval.punctuality' },
  { key: 'followingInstructions', labelKey: 'trials.eval.followingInstructions' },
  { key: 'communicationAndLanguage', labelKey: 'trials.eval.communication' },
  { key: 'cookingFamilyFood', labelKey: 'trials.eval.cooking' },
  { key: 'honestyAndTrustworthiness', labelKey: 'trials.eval.honesty' },
];

const typeNoteKey: Partial<Record<string, TranslationKey>> = {
  trialOffer: 'trials.chat.trialOffer',
  trialAccepted: 'trials.chat.trialAccepted',
  trialDeclined: 'trials.chat.trialDeclined',
  trialCountered: 'trials.chat.trialCountered',
};

function toThreadMessages(msgs: ChatMessageRow[], thread: ChatThreadRow): ThreadMessage[] {
  return msgs.map((m) => {
    const isNanny = m.senderType === 'nanny';
    const author = isNanny ? thread.nannyName ?? translate('trials.nanny') : thread.familyName ?? translate('trials.family');
    const noteKey = m.type && m.type !== 'text' && m.type !== 'image' ? typeNoteKey[m.type] : undefined;
    const note = noteKey ? translate(noteKey) : undefined;
    if (m.type === 'system') {
      return { id: m.id, align: 'left', content: m.content, timestamp: m.createdAt, subtle: true };
    }
    return {
      id: m.id,
      align: isNanny ? 'right' : 'left',
      author: note ? `${author} · ${note}` : author,
      content: m.content,
      timestamp: m.createdAt,
      subtle: !!note,
    };
  });
}

function PartyCard({
  title,
  name,
  photo,
  subtitle,
  to,
  gradientKey,
}: {
  title: string;
  name: string;
  photo?: string;
  subtitle: string;
  to: string;
  gradientKey: string;
}) {
  const { t } = useLocale();
  return (
    <div className="admin-card p-3 flex-1">
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">{title}</div>
      <div className="flex items-center gap-2.5">
        {photo ? (
          <img src={photo} alt={name} className="w-[42px] h-[42px] rounded-xl object-cover bg-[#F4F5FC] flex-shrink-0" />
        ) : (
          <Avatar letter={initials(name)} gradient={gradientFor(gradientKey)} />
        )}
        <div className="flex-1 min-w-0">
          <div className="text-[11px] font-black text-navy truncate">{name}</div>
          <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">{subtitle}</div>
        </div>
        <Link to={to} className="text-[9px] font-bold text-purple font-fredoka no-underline">
          {t('trials.openLink')}
        </Link>
      </div>
    </div>
  );
}

export default function TrialDetail() {
  const { t } = useLocale();
  const { id } = useParams();
  const [trial, setTrial] = useState<TrialAdminRow | null>(null);
  const [nanny, setNanny] = useState<NannyRow | null>(null);
  const [family, setFamily] = useState<FamilyRow | null>(null);
  const [job, setJob] = useState<JobPostRow | null>(null);
  const [thread, setThread] = useState<ChatThreadRow | null>(null);
  const [messages, setMessages] = useState<ChatMessageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    (async () => {
      setError(null);
      try {
        const tr = await TrialService.get(id);
        setTrial(tr);
        if (tr) {
          const [n, f, th] = await Promise.all([
            NannyService.get(tr.nannyId),
            FamilyService.get(tr.familyId),
            ChatService.findThreadByTrial(tr.id),
          ]);
          setNanny(n);
          setFamily(f);
          setThread(th);
          if (tr.jobPostId) setJob(await JobPostService.get(tr.jobPostId));
          if (th) setMessages(await ChatService.listMessages(th.id));
        }
      } catch (e) {
        // Without this the page hangs on "Loading…" forever on any read failure.
        setError((e as Error).message || t('trials.failedToLoadTrial'));
      } finally {
        setLoading(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
  if (error) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-rose-dark">{error}</div>
        </PageContent>
      </PageShell>
    );
  }
  if (!trial) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">{t('trials.trialNotFound')}</div>
        </PageContent>
      </PageShell>
    );
  }

  const dayNum = trialDayNumber(trial);
  const ended = trial.status === 'completed' || trial.status === 'cancelled';
  const pct = Math.min(100, Math.round((dayNum / Math.max(1, trial.durationDays)) * 100));

  return (
    <PageShell>
      <PageHeader
        title={`${trial.nannyName ?? trial.nannyId} ↔ ${trial.familyName ?? trial.familyId}`}
        subtitle={t('trials.hash', { id: trial.id })}
        actions={
          <QaLink to="/trials" variant="n">
            {t('trials.allTrialsLink')}
          </QaLink>
        }
      />
      <PageContent>
        {/* Trial progress */}
        <DetailCard>
          <div className="flex items-center justify-between gap-2">
            <div className="text-[12px] font-black text-navy">
              {t('trials.dayTrialType', { days: trial.durationDays, type: trial.trialType ?? '' })}
            </div>
            <StatusBadge variant={trialStatusVariant(String(trial.status))}>{trialStatusLabel(trial.status)}</StatusBadge>
          </div>
          <div className="mt-3">
            <div className="flex items-center justify-between text-[9px] font-bold text-[#8090B0] mb-1">
              <span>
                {t('trials.dayOf', { day: dayNum, total: trial.durationDays })}
              </span>
              <span className={ended ? 'text-[#A0ADC8]' : 'text-green-dark'}>
                {ended ? t('trials.ended', { date: fmtDate(trial.endDate) }) : t('trials.leftSuffix', { time: trialCountdown(trial) })}
              </span>
            </div>
            <div className="h-2 bg-[#F0F1FA] rounded-full overflow-hidden">
              <div
                className="h-full rounded-full"
                style={{
                  width: `${ended ? 100 : pct}%`,
                  background:
                    trial.status === 'cancelled'
                      ? '#FF5C8A'
                      : trial.status === 'completed'
                        ? '#2E9A58'
                        : 'linear-gradient(90deg,#9B6EDB,#C084FC)',
                }}
              />
            </div>
          </div>
          <FieldGrid>
            <Field label={t('trials.dailyRate')} value={`AED ${trial.dailyRate.toLocaleString()}`} />
            <Field label={t('trials.totalValue')} value={`AED ${trialTotalAmount(trial).toLocaleString()}`} />
            <Field label={t('trials.startDate')} value={fmtDate(trial.startDate)} />
            <Field label={t('common.endDate')} value={fmtDate(trial.endDate)} />
            <Field label={t('trials.location')} value={trial.location || t('common.dash')} />
            <Field label={t('trials.type')} value={trial.trialType || t('common.dash')} />
            <Field
              label={t('trials.familyOutcome')}
              value={
                trial.familyOutcome === 'hired'
                  ? t('trials.outcomeHired')
                  : trial.familyOutcome === 'notHired'
                    ? t('trials.outcomeNotHired')
                    : t('trials.outcomeAwaiting')
              }
            />
            <Field
              label={t('trials.nannyOutcome')}
              value={
                trial.nannyOutcome === 'hired'
                  ? t('trials.outcomeHired')
                  : trial.nannyOutcome === 'notHired'
                    ? t('trials.outcomeNotHired')
                    : t('trials.outcomeAwaiting')
              }
            />
            {trial.notHiredReason && (
              <Field label={t('trials.notHiredReason')} value={trial.notHiredReason} />
            )}
            <Field
              label={t('trials.payment')}
              value={
                trial.paymentIssueReported
                  ? t('trials.paymentIssue')
                  : trial.nannyConfirmedPayment
                    ? t('trials.paymentConfirmed')
                    : t('trials.paymentAwaiting')
              }
            />
          </FieldGrid>
          {trial.notes && <div className="text-[9px] text-navy/70 mt-3">{t('trials.notes', { text: trial.notes })}</div>}
        </DetailCard>

        {/* Parties */}
        <div className="flex flex-col sm:flex-row gap-3 mt-3">
          <PartyCard
            title={t('trials.nanny')}
            name={nanny?.fullName ?? trial.nannyName ?? trial.nannyId}
            photo={nanny?.photoUrls?.[0]}
            subtitle={
              nanny
                ? [nanny.nationality, nanny.city, nanny.experienceYears ? t('common.yearsShort', { count: nanny.experienceYears }) : null]
                    .filter(Boolean)
                    .join(' · ')
                : trial.nannyId
            }
            to={`/nannies/${trial.nannyId}`}
            gradientKey={trial.nannyId}
          />
          <PartyCard
            title={t('trials.family')}
            name={family?.fullName ?? trial.familyName ?? trial.familyId}
            photo={family?.profilePhoto}
            subtitle={
              family
                ? [family.nationality, family.city, family.childrenCount != null ? t('common.childrenCount', { count: family.childrenCount }) : null]
                    .filter(Boolean)
                    .join(' · ')
                : trial.familyId
            }
            to={`/families/${trial.familyId}`}
            gradientKey={trial.familyId}
          />
        </div>

        {/* Job tied to the trial */}
        {job && (
          <Section title={t('trials.jobForTrial')}>
            <div className="flex items-center justify-between gap-2 mt-1">
              <div className="text-[10.5px] font-extrabold text-navy">{job.jobTitle || t('families.jobPostFallback')}</div>
              <Link to={`/families/${job.familyId}`} className="text-[9px] font-bold text-purple font-fredoka no-underline">
                {t('trials.viewFamilyJobs')}
              </Link>
            </div>
            <FieldGrid>
              <Field label={t('trials.roles')} value={listOr(job.rolesNeeded)} />
              <Field label={t('trials.jobType')} value={job.jobType ? jobTypeFullLabel(job.jobType) : t('common.dash')} />
              <Field label={t('trials.daysOff')} value={job.daysOff || t('common.dash')} />
              <Field label={t('trials.salary')} value={salaryRange(job.salaryMin, job.salaryMax)} />
              <Field label={t('trials.visaSponsorship')} value={job.visaSponsorship ? visaSponsorshipLabel(job.visaSponsorship) : t('common.dash')} />
              <Field label={t('trials.duties')} value={listOr(job.duties)} />
              <Field
                label={t('trials.trialTerms')}
                value={job.trialDurationDays ? t('families.trialTerms', { days: job.trialDurationDays, rate: job.trialDailyRate ?? 0 }) : t('common.dash')}
              />
              <Field label={t('trials.benefits')} value={listOr(job.benefits)} />
            </FieldGrid>
          </Section>
        )}

        {/* Evaluation */}
        {trial.evaluation && (
          <Section title={t('trials.familyEvaluation')}>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5 mt-2">
              {EVAL_ITEMS.map((it) => {
                const ok = !!trial.evaluation?.[it.key];
                return (
                  <div key={it.key} className="flex items-center gap-1.5 text-[10px] font-semibold text-navy">
                    <span className={ok ? 'text-green-dark' : 'text-[#C0C8DC]'}>{ok ? '✓' : '○'}</span>
                    {t(it.labelKey)}
                  </div>
                );
              })}
            </div>
            {trial.evaluation.additionalNotes && (
              <div className="text-[9px] text-navy/70 mt-2">{t('trials.evaluationNotes', { text: trial.evaluation.additionalNotes })}</div>
            )}
            {trial.rating != null && (
              <div className="text-[10px] font-bold text-[#FFB347] mt-2">{t('trials.rating', { stars: '★'.repeat(trial.rating) })}</div>
            )}
          </Section>
        )}

        {/* Chat between nanny and family */}
        <Section title={t('trials.trialConversation')}>
          <p className="text-[9px] font-semibold text-[#8090B0] mb-1">
            {t('trials.conversationBetween', { nanny: trial.nannyName ?? t('trials.theNanny'), family: trial.familyName ?? t('trials.theFamily') })}
          </p>
          {thread ? (
            <MessageThread messages={toThreadMessages(messages, thread)} />
          ) : (
            <div className="text-[10px] text-[#8090B0]">{t('trials.noConversationLinked')}</div>
          )}
        </Section>
      </PageContent>
    </PageShell>
  );
}
