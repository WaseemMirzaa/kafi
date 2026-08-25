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
  PageLoader,
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
  trialStatusLabel,
  subscriptionStatusLabel,
  subscriptionPlanLabel,
  yesNo,
  listOr,
  salaryRange,
  fmtDate,
} from '../../utils/nannyLabels';
import { useLocale } from '../../context/LocaleContext';

function JobPostCard({ job }: { job: JobPostRow }) {
  const { t } = useLocale();
  const dash = t('common.dash');
  return (
    <div className="rounded-lg border border-[#EBEEF8] p-3">
      <div className="flex items-center justify-between gap-2">
        <div className="text-[10.5px] font-extrabold text-navy">{job.jobTitle || t('families.jobPostFallback')}</div>
        <StatusBadge variant={jobStatusVariant(job.status)}>{jobPostStatusLabel(job.status)}</StatusBadge>
      </div>
      <div className="text-[8.5px] font-semibold text-[#8090B0] mt-0.5">
        {job.city} · {t('families.postedOn', { date: fmtDate(job.createdAt) })}
        {job.applicationsCount != null ? ` · ${t('families.applicationsCount', { count: job.applicationsCount })}` : ''}
        {job.viewsCount != null ? ` · ${t('families.viewsCount', { count: job.viewsCount })}` : ''}
      </div>
      <FieldGrid>
        <Field label={t('families.rolesNeeded')} value={listOr(job.rolesNeeded)} />
        <Field label={t('families.jobType')} value={job.jobType ? jobTypeFullLabel(job.jobType) : dash} />
        <Field label={t('families.daysOff')} value={job.daysOff || dash} />
        <Field
          label={t('families.start')}
          value={job.startImmediate ? t('families.immediately') : fmtDate(job.startDate)}
        />
        <Field
          label={t('families.duration')}
          value={job.duration ? `${jobDurationLabel(job.duration)}${job.contractMonths ? ` · ${t('common.monthsShort', { count: job.contractMonths })}` : ''}` : dash}
        />
        <Field label={t('families.minExperience')} value={job.experienceYears ? t('common.yearsShort', { count: job.experienceYears }) : dash} />
        <Field label={t('families.salary')} value={salaryRange(job.salaryMin, job.salaryMax)} />
        <Field label={t('families.visaSponsorship')} value={job.visaSponsorship ? visaSponsorshipLabel(job.visaSponsorship) : dash} />
        <Field label={t('families.languagesRequired')} value={listOr(job.languagesRequired)} />
        <Field label={t('families.languagesPreferred')} value={listOr(job.languagesPreferred)} />
        <Field label={t('families.nationalityPreference')} value={listOr(job.nationalityPreference)} />
        <Field label={t('families.religionPreference')} value={job.religionPreference ? religionPreferenceLabel(job.religionPreference) : dash} />
        <Field label={t('trials.duties')} value={listOr(job.duties)} />
        <Field label={t('families.skillsRequired')} value={listOr(job.skillsRequired)} />
        <Field label={t('families.benefits')} value={listOr(job.benefits)} />
        <Field
          label={t('families.trial')}
          value={job.trialDurationDays ? t('families.trialTerms', { days: job.trialDurationDays, rate: job.trialDailyRate ?? 0 }) : dash}
        />
      </FieldGrid>
      {job.additionalNotes && (
        <div className="text-[9px] text-navy/70 mt-2">{t('families.notes', { text: job.additionalNotes })}</div>
      )}
    </div>
  );
}

export default function FamilyDetail() {
  const { t } = useLocale();
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
  // Admin subscription actions (override / reset free contacts).
  const [subBusy, setSubBusy] = useState(false);
  const [actionMsg, setActionMsg] = useState<string | null>(null);
  const [actionErr, setActionErr] = useState<string | null>(null);
  const [showOverride, setShowOverride] = useState(false);
  const [ovStatus, setOvStatus] = useState<FamilyRow['subscription']['status']>('active');
  const [ovPlan, setOvPlan] = useState('');
  const [ovEnd, setOvEnd] = useState('');

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
      setError((e as Error).message || t('families.failedToLoadFamily'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
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
          <button type="button" className="qa-btn qa-n mt-2" onClick={load}>
            {t('common.retry')}
          </button>
        </PageContent>
      </PageShell>
    );
  }
  if (!family) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">{t('common.notFound')}</div>
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
      alert((e as Error).message || t('families.blockToggleFailed'));
    } finally {
      setBusy(false);
    }
  };

  // Manually correct a family's subscription (support/ops). Only the provided
  // fields change; blank plan / end date leave those untouched.
  const applyOverride = async () => {
    setSubBusy(true);
    setActionMsg(null);
    setActionErr(null);
    try {
      await FamilyService.overrideSubscription(family.id, {
        status: ovStatus,
        plan: ovPlan || undefined,
        endDate: ovEnd ? new Date(ovEnd) : undefined,
      });
      setShowOverride(false);
      setActionMsg(t('families.subscriptionUpdated'));
      await load();
    } catch (e) {
      setActionErr((e as Error).message || t('families.failedToUpdateSubscription'));
    } finally {
      setSubBusy(false);
    }
  };

  // Reset the family's used free-contact count back to zero.
  const resetContacts = async () => {
    setSubBusy(true);
    setActionMsg(null);
    setActionErr(null);
    try {
      await FamilyService.resetFreeContacts(family.id);
      setActionMsg(t('families.freeContactsReset'));
      await load();
    } catch (e) {
      setActionErr((e as Error).message || t('families.failedToResetContacts'));
    } finally {
      setSubBusy(false);
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
        subtitle={t('families.profileHash', { id: family.id })}
        actions={
          <>
            <QaLink to="/families" variant="p">
              {t('families.allFamiliesLink')}
            </QaLink>
            <button
              type="button"
              className={`qa-btn ${family.blocked ? 'qa-g' : 'qa-r'}`}
              onClick={toggleBlock}
              disabled={busy}
            >
              {family.blocked ? t('common.unblock') : t('common.block')}
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
                  {subscriptionStatusLabel(sub.status)}
                </StatusBadge>
                {(family.activeTrialNannyIds?.length ?? 0) > 0 && <StatusBadge variant="new">{t('families.trialActive')}</StatusBadge>}
                {family.blocked && <StatusBadge variant="expired">{t('nannies.blockedBadge')}</StatusBadge>}
              </div>
            </div>
          </div>
        </DetailCard>

        {/* Quick stats */}
        <div className="flex flex-wrap gap-1.5 mt-3">
          <ColStat num={String(jobs.length)} label={t('families.jobPosts')} change={t('families.activeCount', { count: jobs.filter((j) => j.status === 'active').length })} />
          <ColStat num={String(apps.length)} label={t('families.offers')} change={t('families.acceptedCount', { count: acceptedOffers })} numColor="#9B6EDB" />
          <ColStat num={String(trials.length)} label={t('families.trials')} change={t('families.completedCount', { count: completedTrials })} />
          <ColStat num={String(cancelledTrials)} label={t('families.cancelled')} change={t('families.trialsLower')} numColor="#FF5C8A" />
          <ColStat num={String(family.stats?.hiresCount ?? 0)} label={t('families.hires')} change={t('families.totalHiresChange')} />
        </div>

        {/* Family profile */}
        <Section title={t('families.familyProfile')}>
          <FieldGrid>
            <Field label={t('families.nationality')} value={family.nationality || t('common.dash')} />
            <Field label={t('families.city')} value={family.city || t('common.dash')} />
            <Field label={t('families.numberOfChildren')} value={family.childrenCount != null ? String(family.childrenCount) : t('common.dash')} />
            <Field label={t('families.childrensAges')} value={listOr(family.childrenAges)} />
            <Field label={t('families.specialNeedsChild')} value={yesNo(family.hasSpecialNeedsChild)} />
            <Field label={t('families.specialNeedsDetails')} value={family.specialNeedsDetails || t('common.dash')} />
            <Field label={t('families.languagesAtHome')} value={listOr(family.languagesAtHome)} />
            <Field label={t('families.homeHasCameras')} value={yesNo(family.hasCameras)} />
            <Field label={t('families.hasPets')} value={yesNo(family.hasPets)} />
            <Field label={t('families.petTypes')} value={listOr(family.petTypes)} />
            <Field label={t('families.religion')} value={family.religion || t('common.dash')} />
            <Field
              label={t('families.nannyReligionPreference')}
              value={family.nannyReligionPreference ? religionPreferenceLabel(family.nannyReligionPreference) : t('common.dash')}
            />
          </FieldGrid>
          {family.houseRules && <div className="text-[9px] text-navy/70 mt-3">{t('families.houseRules', { text: family.houseRules })}</div>}
          {family.aboutFamily && <div className="text-[9px] text-navy/70 mt-1">{t('families.about', { text: family.aboutFamily })}</div>}
        </Section>

        {/* Subscription — view + admin override */}
        <Section title={t('families.subscription')}>
          <FieldGrid>
            <Field label={t('common.status')} value={subscriptionStatusLabel(sub.status)} />
            <Field label={t('families.plan')} value={sub.plan ? subscriptionPlanLabel(sub.plan) : t('families.freeTier')} />
            <Field label={t('families.started')} value={fmtDate(sub.startDate)} />
            <Field label={t('families.ends')} value={fmtDate(sub.endDate)} />
            <Field label={t('families.autoRenew')} value={yesNo(sub.autoRenew)} />
            <Field label={t('families.hasEverSubscribed')} value={yesNo(sub.hasEverSubscribed)} />
            <Field label={t('families.freeContactsUsed')} value={`${family.freeContactsUsed ?? 0} / ${freeLimit}`} />
            <Field label={t('families.activeTrialsField')} value={String(family.activeTrialNannyIds?.length ?? 0)} />
          </FieldGrid>

          <div className="mt-4 flex flex-wrap items-center gap-2">
            <button
              type="button"
              className="qa-btn qa-n"
              onClick={() => {
                setActionErr(null);
                setActionMsg(null);
                setShowOverride((v) => !v);
              }}
              disabled={subBusy}
            >
              {showOverride ? t('families.closeOverride') : t('families.overrideSubscription')}
            </button>
            <button type="button" className="qa-btn qa-n" onClick={resetContacts} disabled={subBusy}>
              {t('families.resetFreeContacts')}
            </button>
            {actionMsg && <span className="text-[10px] font-bold text-[#2A8A50]">{actionMsg}</span>}
            {actionErr && <span className="text-[10px] font-bold text-rose-dark">{actionErr}</span>}
          </div>

          {showOverride && (
            <div className="mt-3 rounded-lg border border-[#EBEEF8] p-3">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-1.5">{t('common.status')}</div>
                  <select
                    value={ovStatus}
                    onChange={(e) => setOvStatus(e.target.value as FamilyRow['subscription']['status'])}
                    className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
                  >
                    <option value="active">{subscriptionStatusLabel('active')}</option>
                    <option value="free">{subscriptionStatusLabel('free')}</option>
                    <option value="expired">{subscriptionStatusLabel('expired')}</option>
                    <option value="cancelled">{subscriptionStatusLabel('cancelled')}</option>
                  </select>
                </div>
                <div>
                  <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-1.5">{t('common.plan')}</div>
                  <select
                    value={ovPlan}
                    onChange={(e) => setOvPlan(e.target.value)}
                    className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
                  >
                    <option value="">{t('common.leaveUnchanged')}</option>
                    <option value="weekly">{subscriptionPlanLabel('weekly')}</option>
                    <option value="monthly">{subscriptionPlanLabel('monthly')}</option>
                    <option value="twoMonths">{subscriptionPlanLabel('twoMonths')}</option>
                  </select>
                </div>
                <div>
                  <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-1.5">{t('common.endDate')}</div>
                  <input
                    type="date"
                    value={ovEnd}
                    onChange={(e) => setOvEnd(e.target.value)}
                    className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
                  />
                </div>
              </div>
              <div className="text-[8px] text-[#8090B0] mt-2 leading-relaxed">
                {t('families.overrideApplies')}
              </div>
              <button type="button" className="qa-btn qa-r mt-3" onClick={applyOverride} disabled={subBusy}>
                {subBusy ? t('common.applying') : t('families.applyOverride')}
              </button>
            </div>
          )}
        </Section>

        {/* Job posts */}
        <Section title={t('families.jobPostsCount', { count: jobs.length })}>
          {jobs.length === 0 ? (
            <div className="text-[10px] text-[#8090B0] mt-2">{t('families.noJobPosts')}</div>
          ) : (
            <div className="flex flex-col gap-3 mt-2">
              {jobs.map((j) => (
                <JobPostCard key={j.id} job={j} />
              ))}
            </div>
          )}
        </Section>

        {/* Offers / applications */}
        <Section title={t('families.offersApplicationsCount', { count: apps.length })}>
          {apps.length === 0 ? (
            <div className="text-[10px] text-[#8090B0] mt-2">{t('families.noApplications')}</div>
          ) : (
            <div className="flex flex-col gap-1.5 mt-2">
              {apps.map((a) => (
                <div key={a.id} className="flex items-center gap-2 rounded-lg border border-[#EBEEF8] px-2.5 py-2">
                  <div className="flex-1 min-w-0">
                    <div className="text-[10px] font-extrabold text-navy truncate">
                      {a.nannyName ?? a.nannyId}
                      {a.matchScore != null && <span className="text-[#8090B0] font-semibold"> · {t('families.matchPercent', { pct: a.matchScore })}</span>}
                    </div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                      {a.jobTitle ?? a.jobPostId} · {fmtDate(a.createdAt)}
                    </div>
                  </div>
                  <StatusBadge variant={applicationStatusVariant(a.status)}>{applicationStatusLabel(a.status)}</StatusBadge>
                </div>
              ))}
            </div>
          )}
        </Section>

        {/* Trials */}
        <Section title={t('families.trialsCount', { count: trials.length })}>
          {trials.length === 0 ? (
            <div className="text-[10px] text-[#8090B0] mt-2">{t('families.noTrials')}</div>
          ) : (
            <div className="flex flex-col gap-1.5 mt-2">
              {trials.map((trial) => (
                <div key={trial.id} className="flex items-center gap-2 rounded-lg border border-[#EBEEF8] px-2.5 py-2">
                  <div className="flex-1 min-w-0">
                    <div className="text-[10px] font-extrabold text-navy truncate">
                      {trial.nannyName ?? trial.nannyId}
                      {trial.rating != null && <span className="text-[#FFB347] font-bold"> · {trial.rating}★</span>}
                    </div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                      {trial.trialType ?? ''} · {t('families.trialTerms', { days: trial.durationDays, rate: trial.dailyRate })} · {fmtDate(trial.startDate)}
                      {trial.outcome ? ` · ${trial.outcome}` : ''}
                    </div>
                  </div>
                  <StatusBadge variant={trialStatusVariant(String(trial.status))}>{trialStatusLabel(trial.status)}</StatusBadge>
                </div>
              ))}
            </div>
          )}
        </Section>

        {/* Conversations */}
        <Section title={t('families.conversationsWithNannies', { count: threads.length })}>
          <ConversationsPanel threads={threads} counterpart="nanny" />
        </Section>
      </PageContent>
    </PageShell>
  );
}
