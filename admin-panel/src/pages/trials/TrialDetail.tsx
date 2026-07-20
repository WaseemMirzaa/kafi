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
  fmtDate,
  jobTypeFullLabel,
  visaSponsorshipLabel,
  salaryRange,
  listOr,
} from '../../utils/nannyLabels';
import { trialDayNumber, trialCountdown, trialTotalAmount } from '../../utils/trials';

const EVAL_ITEMS: { key: keyof NonNullable<TrialAdminRow['evaluation']>; label: string }[] = [
  { key: 'childInteractionAndPatience', label: 'Child interaction & patience' },
  { key: 'punctualityAndReliability', label: 'Punctuality & reliability' },
  { key: 'followingInstructions', label: 'Following instructions' },
  { key: 'communicationAndLanguage', label: 'Communication & language' },
  { key: 'cookingFamilyFood', label: 'Cooking family food' },
  { key: 'honestyAndTrustworthiness', label: 'Honesty & trustworthiness' },
];

const typeNote: Record<string, string> = {
  trialOffer: 'sent a trial offer',
  trialAccepted: 'accepted the trial offer',
  trialDeclined: 'declined the trial offer',
  trialCountered: 'sent a counter-offer',
};

function toThreadMessages(msgs: ChatMessageRow[], thread: ChatThreadRow): ThreadMessage[] {
  return msgs.map((m) => {
    const isNanny = m.senderType === 'nanny';
    const author = isNanny ? thread.nannyName ?? 'Nanny' : thread.familyName ?? 'Family';
    const note = m.type && m.type !== 'text' && m.type !== 'image' ? typeNote[m.type] : undefined;
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
          Open →
        </Link>
      </div>
    </div>
  );
}

export default function TrialDetail() {
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
        const t = await TrialService.get(id);
        setTrial(t);
        if (t) {
          const [n, f, th] = await Promise.all([
            NannyService.get(t.nannyId),
            FamilyService.get(t.familyId),
            ChatService.findThreadByTrial(t.id),
          ]);
          setNanny(n);
          setFamily(f);
          setThread(th);
          if (t.jobPostId) setJob(await JobPostService.get(t.jobPostId));
          if (th) setMessages(await ChatService.listMessages(th.id));
        }
      } catch (e) {
        // Without this the page hangs on "Loading…" forever on any read failure.
        setError((e as Error).message || 'Failed to load trial');
      } finally {
        setLoading(false);
      }
    })();
  }, [id]);

  if (loading) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">Loading…</div>
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
          <div className="text-[10px] text-[#8090B0]">Trial not found.</div>
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
        subtitle={`Trial #${trial.id}`}
        actions={
          <QaLink to="/trials" variant="n">
            ← All trials
          </QaLink>
        }
      />
      <PageContent>
        {/* Trial progress */}
        <DetailCard>
          <div className="flex items-center justify-between gap-2">
            <div className="text-[12px] font-black text-navy">
              {trial.durationDays}-day {trial.trialType ?? ''} trial
            </div>
            <StatusBadge variant={trialStatusVariant(String(trial.status))}>{String(trial.status)}</StatusBadge>
          </div>
          <div className="mt-3">
            <div className="flex items-center justify-between text-[9px] font-bold text-[#8090B0] mb-1">
              <span>
                Day {dayNum} of {trial.durationDays}
              </span>
              <span className={ended ? 'text-[#A0ADC8]' : 'text-green-dark'}>
                {ended ? `Ended ${fmtDate(trial.endDate)}` : `${trialCountdown(trial)} left`}
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
            <Field label="Daily rate" value={`AED ${trial.dailyRate.toLocaleString()}`} />
            <Field label="Total value" value={`AED ${trialTotalAmount(trial).toLocaleString()}`} />
            <Field label="Start date" value={fmtDate(trial.startDate)} />
            <Field label="End date" value={fmtDate(trial.endDate)} />
            <Field label="Location" value={trial.location || '—'} />
            <Field label="Type" value={trial.trialType || '—'} />
            <Field label="Outcome" value={trial.outcome || '—'} />
            <Field
              label="Payment"
              value={
                trial.paymentIssueReported
                  ? '⚠ Issue reported'
                  : trial.nannyConfirmedPayment
                    ? '✓ Confirmed by nanny'
                    : 'Awaiting confirmation'
              }
            />
          </FieldGrid>
          {trial.notes && <div className="text-[9px] text-navy/70 mt-3">Notes: {trial.notes}</div>}
        </DetailCard>

        {/* Parties */}
        <div className="flex flex-col sm:flex-row gap-3 mt-3">
          <PartyCard
            title="Nanny"
            name={nanny?.fullName ?? trial.nannyName ?? trial.nannyId}
            photo={nanny?.photoUrls?.[0]}
            subtitle={
              nanny
                ? [nanny.nationality, nanny.city, nanny.experienceYears ? `${nanny.experienceYears} yrs` : null]
                    .filter(Boolean)
                    .join(' · ')
                : trial.nannyId
            }
            to={`/nannies/${trial.nannyId}`}
            gradientKey={trial.nannyId}
          />
          <PartyCard
            title="Family"
            name={family?.fullName ?? trial.familyName ?? trial.familyId}
            photo={family?.profilePhoto}
            subtitle={
              family
                ? [family.nationality, family.city, family.childrenCount != null ? `${family.childrenCount} children` : null]
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
          <Section title="Job for this trial">
            <div className="flex items-center justify-between gap-2 mt-1">
              <div className="text-[10.5px] font-extrabold text-navy">{job.jobTitle || 'Job post'}</div>
              <Link to={`/families/${job.familyId}`} className="text-[9px] font-bold text-purple font-fredoka no-underline">
                View family jobs →
              </Link>
            </div>
            <FieldGrid>
              <Field label="Roles" value={listOr(job.rolesNeeded)} />
              <Field label="Job type" value={job.jobType ? jobTypeFullLabel[job.jobType] : '—'} />
              <Field label="Schedule" value={job.schedule || '—'} />
              <Field label="Salary" value={salaryRange(job.salaryMin, job.salaryMax)} />
              <Field label="Visa sponsorship" value={job.visaSponsorship ? visaSponsorshipLabel[job.visaSponsorship] : '—'} />
              <Field label="Duties" value={listOr(job.duties)} />
              <Field
                label="Trial terms"
                value={job.trialDurationDays ? `${job.trialDurationDays} days @ AED ${job.trialDailyRate}/day` : '—'}
              />
              <Field label="Benefits" value={listOr(job.benefits)} />
            </FieldGrid>
          </Section>
        )}

        {/* Evaluation */}
        {trial.evaluation && (
          <Section title="Family evaluation">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5 mt-2">
              {EVAL_ITEMS.map((it) => {
                const ok = !!trial.evaluation?.[it.key];
                return (
                  <div key={it.key} className="flex items-center gap-1.5 text-[10px] font-semibold text-navy">
                    <span className={ok ? 'text-green-dark' : 'text-[#C0C8DC]'}>{ok ? '✓' : '○'}</span>
                    {it.label}
                  </div>
                );
              })}
            </div>
            {trial.evaluation.additionalNotes && (
              <div className="text-[9px] text-navy/70 mt-2">Notes: {trial.evaluation.additionalNotes}</div>
            )}
            {trial.rating != null && (
              <div className="text-[10px] font-bold text-[#FFB347] mt-2">Rating: {'★'.repeat(trial.rating)}</div>
            )}
          </Section>
        )}

        {/* Chat between nanny and family */}
        <Section title="Trial conversation">
          <p className="text-[9px] font-semibold text-[#8090B0] mb-1">
            Messages between {trial.nannyName ?? 'the nanny'} and {trial.familyName ?? 'the family'} (read-only).
          </p>
          {thread ? (
            <MessageThread messages={toThreadMessages(messages, thread)} />
          ) : (
            <div className="text-[10px] text-[#8090B0]">No conversation linked to this trial.</div>
          )}
        </Section>
      </PageContent>
    </PageShell>
  );
}
