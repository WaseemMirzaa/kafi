import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import {
  Avatar,
  ColStat,
  DetailCard,
  Field,
  FieldGrid,
  PageContent,
  PageHeader,
  PageShell,
  QaLink,
  StatusBadge,
} from '../../components/ui/AdminUI';
import {
  FamilyService,
  FamilyRow,
  JobPostService,
  JobPostRow,
  ApplicationService,
  ApplicationRow,
  TrialService,
  TrialAdminRow,
  ChatService,
  ChatThreadRow,
  SettingsService,
} from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { Section } from '../../components/nanny/NannyProfileView';
import { ConversationsPanel } from '../../components/chat/ConversationsPanel';
import {
  religionPreferenceLabel,
  jobTypeFullLabel,
  jobDurationLabel,
  visaSponsorshipLabel,
  jobPostStatusLabel,
  jobStatusVariant,
  applicationStatusLabel,
  applicationStatusVariant,
  trialStatusVariant,
  label,
  yesNo,
  listOr,
  salaryRange,
  fmtDate,
} from '../../utils/nannyLabels';

function JobPostCard({ job }: { job: JobPostRow }) {
  return (
    <div className="rounded-lg border border-[#EBEEF8] p-3">
      <div className="flex items-center justify-between gap-2">
        <div className="text-[10.5px] font-extrabold text-navy">{job.jobTitle || 'Job post'}</div>
        <StatusBadge variant={jobStatusVariant(job.status)}>{jobPostStatusLabel[job.status]}</StatusBadge>
      </div>
      <div className="text-[8.5px] font-semibold text-[#8090B0] mt-0.5">
        {job.city} · Posted {fmtDate(job.createdAt)}
        {job.applicationsCount != null ? ` · ${job.applicationsCount} applications` : ''}
        {job.viewsCount != null ? ` · ${job.viewsCount} views` : ''}
      </div>
      <FieldGrid>
        <Field label="Roles needed" value={listOr(job.rolesNeeded)} />
        <Field label="Job type" value={job.jobType ? jobTypeFullLabel[job.jobType] : '—'} />
        <Field label="Schedule" value={job.schedule || '—'} />
        <Field
          label="Start"
          value={job.startImmediate ? 'Immediately' : fmtDate(job.startDate)}
        />
        <Field
          label="Duration"
          value={job.duration ? `${jobDurationLabel[job.duration]}${job.contractMonths ? ` · ${job.contractMonths} mo` : ''}` : '—'}
        />
        <Field label="Min. experience" value={job.experienceYears ? `${job.experienceYears} yrs` : '—'} />
        <Field label="Salary" value={salaryRange(job.salaryMin, job.salaryMax)} />
        <Field label="Visa sponsorship" value={job.visaSponsorship ? visaSponsorshipLabel[job.visaSponsorship] : '—'} />
        <Field label="Languages required" value={listOr(job.languagesRequired)} />
        <Field label="Languages preferred" value={listOr(job.languagesPreferred)} />
        <Field label="Nationality preference" value={listOr(job.nationalityPreference)} />
        <Field label="Religion preference" value={job.religionPreference ? religionPreferenceLabel[job.religionPreference] : '—'} />
        <Field label="Duties" value={listOr(job.duties)} />
        <Field label="Skills required" value={listOr(job.skillsRequired)} />
        <Field label="Benefits" value={listOr(job.benefits)} />
        <Field
          label="Trial"
          value={job.trialDurationDays ? `${job.trialDurationDays} days @ AED ${job.trialDailyRate}/day` : '—'}
        />
      </FieldGrid>
      {job.additionalNotes && (
        <div className="text-[9px] text-navy/70 mt-2">Notes: {job.additionalNotes}</div>
      )}
    </div>
  );
}

export default function FamilyDetail() {
  const { id } = useParams();
  const [family, setFamily] = useState<FamilyRow | null>(null);
  const [jobs, setJobs] = useState<JobPostRow[]>([]);
  const [apps, setApps] = useState<ApplicationRow[]>([]);
  const [trials, setTrials] = useState<TrialAdminRow[]>([]);
  const [threads, setThreads] = useState<ChatThreadRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [freeLimit, setFreeLimit] = useState(5);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    setError(null);
    try {
      const [f, j, a, t, th, s] = await Promise.all([
        FamilyService.get(id),
        JobPostService.listByFamily(id),
        ApplicationService.listByFamily(id),
        TrialService.listByFamily(id),
        ChatService.listThreadsForFamily(id),
        SettingsService.get(),
      ]);
      setFamily(f);
      setJobs(j);
      setApps(a);
      setTrials(t);
      setThreads(th);
      setFreeLimit(s.freeContactLimit ?? 5);
    } catch (e) {
      // Without this the page hangs on "Loading…" forever on any read failure.
      setError((e as Error).message || 'Failed to load family');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
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
          <button type="button" className="qa-btn qa-n mt-2" onClick={load}>
            Retry
          </button>
        </PageContent>
      </PageShell>
    );
  }
  if (!family) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">Not found.</div>
        </PageContent>
      </PageShell>
    );
  }

  const toggleBlock = async () => {
    setBusy(true);
    try {
      if (family.blocked) await FamilyService.unblock(family.id);
      else await FamilyService.block(family.id);
      load();
    } catch (e) {
      alert((e as Error).message || 'Block toggle failed');
    } finally {
      setBusy(false);
    }
  };

  const completedTrials = trials.filter((t) => t.status === 'completed').length;
  const cancelledTrials = trials.filter((t) => t.status === 'cancelled').length;
  const acceptedOffers = apps.filter((a) => a.status === 'hired' || a.status === 'trialOffered').length;
  const sub = family.subscription;

  return (
    <PageShell>
      <PageHeader
        title={family.fullName}
        subtitle={`Profile #${family.id}`}
        actions={
          <>
            <QaLink to="/families" variant="p">
              ← All families
            </QaLink>
            <button
              type="button"
              className={`qa-btn ${family.blocked ? 'qa-g' : 'qa-r'}`}
              onClick={toggleBlock}
              disabled={busy}
            >
              {family.blocked ? 'Unblock' : 'Block'}
            </button>
          </>
        }
      />
      <PageContent>
        <DetailCard>
          <div className="flex items-center gap-4">
            {family.profilePhoto ? (
              <img
                src={family.profilePhoto}
                alt={family.fullName}
                className="w-[52px] h-[52px] rounded-xl object-cover flex-shrink-0 bg-[#F4F5FC]"
              />
            ) : (
              <Avatar letter={initials(family.fullName)} gradient={gradientFor(family.id)} />
            )}
            <div className="flex-1">
              <div className="text-[13px] font-black text-navy">{family.fullName}</div>
              <div className="text-[9px] font-semibold text-[#8090B0] mt-0.5">
                {family.nationality} · {family.city}
              </div>
              <div className="mt-2 flex gap-1.5 flex-wrap">
                <StatusBadge variant={sub.status === 'active' ? 'sub' : sub.status === 'free' ? 'unsub' : 'expired'}>
                  {sub.status}
                </StatusBadge>
                {(family.activeTrialNannyIds?.length ?? 0) > 0 && <StatusBadge variant="new">Trial active</StatusBadge>}
                {family.blocked && <StatusBadge variant="expired">Blocked</StatusBadge>}
              </div>
            </div>
          </div>
        </DetailCard>

        {/* Quick stats */}
        <div className="flex flex-wrap gap-1.5 mt-3">
          <ColStat num={String(jobs.length)} label="Job posts" change={`${jobs.filter((j) => j.status === 'active').length} active`} />
          <ColStat num={String(apps.length)} label="Offers" change={`${acceptedOffers} accepted`} numColor="#9B6EDB" />
          <ColStat num={String(trials.length)} label="Trials" change={`${completedTrials} completed`} />
          <ColStat num={String(cancelledTrials)} label="Cancelled" change="trials" numColor="#FF5C8A" />
          <ColStat num={String(family.stats?.hiresCount ?? 0)} label="Hires" change="↑ total" />
        </div>

        {/* Family profile */}
        <Section title="Family profile">
          <FieldGrid>
            <Field label="Nationality" value={family.nationality || '—'} />
            <Field label="City" value={family.city || '—'} />
            <Field label="Number of children" value={family.childrenCount != null ? String(family.childrenCount) : '—'} />
            <Field label="Children's ages" value={listOr(family.childrenAges)} />
            <Field label="Special needs child" value={yesNo(family.hasSpecialNeedsChild)} />
            <Field label="Special needs details" value={family.specialNeedsDetails || '—'} />
            <Field label="Languages at home" value={listOr(family.languagesAtHome)} />
            <Field label="Home has cameras" value={yesNo(family.hasCameras)} />
            <Field label="Has pets" value={yesNo(family.hasPets)} />
            <Field label="Pet types" value={listOr(family.petTypes)} />
            <Field label="Religion" value={family.religion || '—'} />
            <Field
              label="Nanny religion preference"
              value={family.nannyReligionPreference ? label(religionPreferenceLabel, family.nannyReligionPreference) : '—'}
            />
          </FieldGrid>
          {family.houseRules && <div className="text-[9px] text-navy/70 mt-3">House rules: {family.houseRules}</div>}
          {family.aboutFamily && <div className="text-[9px] text-navy/70 mt-1">About: {family.aboutFamily}</div>}
        </Section>

        {/* Subscription — view only */}
        <Section title="Subscription (view only)">
          <FieldGrid>
            <Field label="Status" value={sub.status} />
            <Field label="Plan" value={sub.plan ?? 'Free tier'} />
            <Field label="Started" value={fmtDate(sub.startDate)} />
            <Field label="Ends" value={fmtDate(sub.endDate)} />
            <Field label="Auto-renew" value={yesNo(sub.autoRenew)} />
            <Field label="Has ever subscribed" value={yesNo(sub.hasEverSubscribed)} />
            <Field label="Free contacts used" value={`${family.freeContactsUsed ?? 0} / ${freeLimit}`} />
            <Field label="Active trials" value={String(family.activeTrialNannyIds?.length ?? 0)} />
          </FieldGrid>
        </Section>

        {/* Job posts */}
        <Section title={`Job posts (${jobs.length})`}>
          {jobs.length === 0 ? (
            <div className="text-[10px] text-[#8090B0] mt-2">No job posts.</div>
          ) : (
            <div className="flex flex-col gap-3 mt-2">
              {jobs.map((j) => (
                <JobPostCard key={j.id} job={j} />
              ))}
            </div>
          )}
        </Section>

        {/* Offers / applications */}
        <Section title={`Offers & applications (${apps.length})`}>
          {apps.length === 0 ? (
            <div className="text-[10px] text-[#8090B0] mt-2">No applications.</div>
          ) : (
            <div className="flex flex-col gap-1.5 mt-2">
              {apps.map((a) => (
                <div key={a.id} className="flex items-center gap-2 rounded-lg border border-[#EBEEF8] px-2.5 py-2">
                  <div className="flex-1 min-w-0">
                    <div className="text-[10px] font-extrabold text-navy truncate">
                      {a.nannyName ?? a.nannyId}
                      {a.matchScore != null && <span className="text-[#8090B0] font-semibold"> · {a.matchScore}% match</span>}
                    </div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                      {a.jobTitle ?? a.jobPostId} · {fmtDate(a.createdAt)}
                    </div>
                  </div>
                  <StatusBadge variant={applicationStatusVariant(a.status)}>{applicationStatusLabel[a.status]}</StatusBadge>
                </div>
              ))}
            </div>
          )}
        </Section>

        {/* Trials */}
        <Section title={`Trials (${trials.length})`}>
          {trials.length === 0 ? (
            <div className="text-[10px] text-[#8090B0] mt-2">No trials.</div>
          ) : (
            <div className="flex flex-col gap-1.5 mt-2">
              {trials.map((t) => (
                <div key={t.id} className="flex items-center gap-2 rounded-lg border border-[#EBEEF8] px-2.5 py-2">
                  <div className="flex-1 min-w-0">
                    <div className="text-[10px] font-extrabold text-navy truncate">
                      {t.nannyName ?? t.nannyId}
                      {t.rating != null && <span className="text-[#FFB347] font-bold"> · {t.rating}★</span>}
                    </div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                      {t.trialType ?? ''} · {t.durationDays} days @ AED {t.dailyRate}/day · {fmtDate(t.startDate)}
                      {t.outcome ? ` · ${t.outcome}` : ''}
                    </div>
                  </div>
                  <StatusBadge variant={trialStatusVariant(String(t.status))}>{String(t.status)}</StatusBadge>
                </div>
              ))}
            </div>
          )}
        </Section>

        {/* Conversations */}
        <Section title={`Conversations with nannies (${threads.length})`}>
          <ConversationsPanel threads={threads} counterpart="nanny" />
        </Section>
      </PageContent>
    </PageShell>
  );
}
