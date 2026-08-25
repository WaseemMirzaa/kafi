import { NannyRow } from '../../services/firestore';
import { Field, FieldGrid, StatusBadge } from '../ui/AdminUI';
import { DocViewer } from './DocFilePreview';
import {
  visaStatusLabel,
  availabilityLabel,
  jobTypeLabel,
  maritalStatusLabel,
  yesNo,
  salaryRange,
  emiratesList,
  listOr,
  formatDate,
  fmtDate,
  docStatusLabel,
} from '../../utils/nannyLabels';
import { useLocale } from '../../context/LocaleContext';
import { t as translate, TranslationKey } from '../../locales/t';

/** A titled card section grouping related profile fields. */
export function Section({
  title,
  children,
  className = '',
}: {
  title: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`admin-card p-4 mt-3 ${className}`}>
      <h4 className="text-[11px] font-extrabold text-navy">{title}</h4>
      {children}
    </div>
  );
}

const docLabelKeys: Record<string, TranslationKey> = {
  passport: 'nannyLabels.docType.passport',
  visa: 'nannyLabels.docType.visa',
  emiratesId: 'nannyLabels.docType.emiratesId',
  trainingCert: 'nannyLabels.docType.trainingCert',
  policeClearance: 'nannyLabels.docType.policeClearance',
};
const docLabel = (type: string): string => (docLabelKeys[type] ? translate(docLabelKeys[type]) : type);

function docVariant(status: string): string {
  if (status === 'approved') return 'verified';
  if (status === 'rejected' || status === 'missing') return 'rejected';
  if (status === 'resubmitted') return 'new';
  return 'verify';
}

/** Read-only document grid — renders images, videos, PDFs and other formats. */
export function DocumentsGrid({ nanny }: { nanny: NannyRow }) {
  const { t } = useLocale();
  const docs = nanny.documents ?? [];
  if (docs.length === 0) {
    return <div className="text-[10px] text-[#8090B0] mt-2">{t('nannies.noDocumentsUploadedShort')}</div>;
  }
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-3">
      {docs.map((doc, i) => (
        <div key={doc.type + i} className="rounded-lg border border-[#EBEEF8] overflow-hidden">
          <div className="p-2">
            <DocViewer url={doc.url} label={docLabel(doc.type)} />
          </div>
          <div className="flex items-center justify-between gap-1 px-2 py-1.5 border-t border-[#EBEEF8]">
            <div className="text-[9px] font-extrabold text-navy truncate">{docLabel(doc.type)}</div>
            <StatusBadge variant={docVariant(doc.status)}>{docStatusLabel(doc.status)}</StatusBadge>
          </div>
          {doc.rejectionReason && (
            <div className="px-2 pb-1.5 text-[8px] font-semibold text-rose-dark">{doc.rejectionReason}</div>
          )}
        </div>
      ))}
    </div>
  );
}

/** Full read-only nanny profile — every attribute the nanny submits in the app.
 *  Reused by the nanny detail page and the document-verification queue. */
export function NannyProfileView({
  nanny,
  showDocuments = true,
  onReviewVideo,
  videoBusy = false,
}: {
  nanny: NannyRow;
  showDocuments?: boolean;
  /** When provided, the intro-video section renders Approve/Reject controls
   *  wired to this callback (calls `NannyService.reviewVideo`). Omit it for the
   *  read-only contexts (e.g. the verification queue). */
  onReviewVideo?: (status: 'approved' | 'rejected') => void;
  videoBusy?: boolean;
}) {
  const { t } = useLocale();
  const dash = t('common.dash');
  return (
    <>
      {nanny.bio && (
        <Section title={t('nannies.about')}>
          <p className="text-[10.5px] font-semibold text-navy/80 leading-relaxed mt-2">{nanny.bio}</p>
        </Section>
      )}

      {(nanny.photoUrls?.length || 0) > 0 && (
        <Section title={t('nannies.photosCount', { count: nanny.photoUrls!.length })}>
          <div className="flex flex-wrap gap-2 mt-2">
            {nanny.photoUrls!.map((url, i) => (
              <a key={url + i} href={url} target="_blank" rel="noreferrer">
                <img
                  src={url}
                  alt={`${nanny.fullName} ${i + 1}`}
                  className="w-20 h-20 rounded-lg object-cover border border-[#EBEEF8] bg-[#F4F5FC]"
                  loading="lazy"
                />
              </a>
            ))}
          </div>
        </Section>
      )}

      <Section title={t('nannies.personalDemographics')}>
        <FieldGrid>
          <Field label={t('nannies.fullName')} value={nanny.fullName || dash} />
          <Field label={t('nannies.nationality')} value={nanny.nationality || dash} />
          <Field label={t('nannies.dateOfBirth')} value={formatDate(nanny.dateOfBirth)} />
          <Field label={t('nannies.age')} value={nanny.age ? `${nanny.age}` : dash} />
          <Field label={t('nannies.city')} value={nanny.city || dash} />
          <Field label={t('nannies.currentArea')} value={nanny.currentArea || dash} />
          <Field label={t('nannies.maritalStatus')} value={maritalStatusLabel(nanny.maritalStatus)} />
          <Field label={t('nannies.hasChildren')} value={yesNo(nanny.hasChildren)} />
          <Field label={t('nannies.numberOfChildren')} value={nanny.childrenCount != null ? String(nanny.childrenCount) : dash} />
          <Field label={t('nannies.childrensAges')} value={nanny.childrenAges || dash} />
          <Field
            label={t('nannies.lastActive')}
            value={fmtDate(nanny.lastActiveAt)}
          />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.languagesCommunication')}>
        <FieldGrid>
          <Field label={t('nannies.languages')} value={listOr(nanny.languages)} />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.visaAndEid')}>
        <FieldGrid>
          <Field label={t('nannies.visaStatus')} value={visaStatusLabel(nanny.visaStatus)} />
          <Field label={t('nannies.hasEmiratesId')} value={yesNo(nanny.hasEmiratesId)} />
          <Field label={t('nannies.eidNumber')} value={nanny.eidNumber || dash} />
          <Field label={t('nannies.willingToTransferVisa')} value={yesNo(nanny.willingToTransferVisa)} />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.workLocationAvailability')}>
        <FieldGrid>
          <Field label={t('nannies.workEmirates')} value={emiratesList(nanny.workEmirates)} />
          <Field label={t('nannies.willingToRelocate')} value={yesNo(nanny.willingToRelocate)} />
          <Field label={t('nannies.availability')} value={availabilityLabel(nanny.availability)} />
          <Field label={t('nannies.availableFrom')} value={formatDate(nanny.availableFrom)} />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.jobPreferencesCompensation')}>
        <FieldGrid>
          <Field label={t('nannies.jobTypePreference')} value={jobTypeLabel(nanny.jobTypePreference)} />
          <Field label={t('nannies.expectedSalary')} value={salaryRange(nanny.expectedSalaryMin, nanny.expectedSalaryMax)} />
          <Field label={t('nannies.canDoNightShifts')} value={yesNo(nanny.canDoNightShifts)} />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.skillsHouseholdPreferences')}>
        <FieldGrid>
          <Field label={t('nannies.canCook')} value={yesNo(nanny.canCook)} />
          <Field label={t('nannies.cuisines')} value={listOr(nanny.cuisines)} />
          <Field label={t('nannies.comfortableWithPets')} value={yesNo(nanny.comfortableWithPets)} />
          <Field label={t('nannies.petTypes')} value={listOr(nanny.petTypes)} />
          <Field label={t('nannies.comfortableWithCameras')} value={yesNo(nanny.comfortableWithCameras)} />
          <Field label={t('nannies.cameraNote')} value={nanny.cameraNote || dash} />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.health')}>
        <FieldGrid>
          <Field label={t('nannies.hasHealthConditions')} value={yesNo(nanny.hasHealthConditions)} />
          <Field label={t('nannies.healthConditions')} value={nanny.healthConditions || dash} />
          <Field label={t('nannies.takesMedication')} value={yesNo(nanny.takesMedication)} />
          <Field label={t('nannies.medications')} value={nanny.medications || dash} />
          <Field label={t('nannies.hasAllergies')} value={yesNo(nanny.hasAllergies)} />
          <Field label={t('nannies.allergies')} value={nanny.allergies || dash} />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.religionCultural')}>
        <FieldGrid>
          <Field label={t('nannies.religion')} value={nanny.religion || dash} />
          <Field label={t('nannies.religiousNotes')} value={nanny.religiousNotes || dash} />
          <Field label={t('nannies.comfortableWithDifferentFaith')} value={yesNo(nanny.comfortableWithDifferentFaith)} />
        </FieldGrid>
      </Section>

      <Section title={t('nannies.emergencyContact')}>
        <FieldGrid>
          <Field label={t('nannies.emergencyName')} value={nanny.emergencyName || dash} />
          <Field label={t('nannies.emergencyRelationship')} value={nanny.emergencyRelationship || dash} />
          <Field label={t('nannies.emergencyPhone')} value={nanny.emergencyPhone || dash} />
        </FieldGrid>
      </Section>

      {nanny.experiences && nanny.experiences.length > 0 && (
        <Section title={t('nannies.workExperienceCount', { count: nanny.experiences.length })}>
          <div className="mt-2 flex flex-col gap-2">
            {nanny.experiences.map((exp, i) => (
              <div key={exp.id ?? i} className="rounded-lg border border-[#EBEEF8] p-2.5">
                <div className="flex items-center justify-between">
                  <div className="text-[10.5px] font-extrabold text-navy">{exp.jobTitle}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0]">
                    {formatDate(exp.fromDate)} – {formatDate(exp.toDate)}
                  </div>
                </div>
                <div className="text-[9px] font-semibold text-[#8090B0] mt-0.5">
                  {exp.employer}
                  {exp.cityCountry ? ` · ${exp.cityCountry}` : ''}
                </div>
                {exp.children && <div className="text-[9px] text-navy/70 mt-1">{t('nannies.children')}: {exp.children}</div>}
                {exp.duties && <div className="text-[9px] text-navy/70 mt-0.5">{t('nannies.duties')}: {exp.duties}</div>}
                {exp.reasonLeaving && (
                  <div className="text-[9px] text-navy/70 mt-0.5">{t('nannies.reasonForLeaving')}: {exp.reasonLeaving}</div>
                )}
              </div>
            ))}
          </div>
        </Section>
      )}

      <Section title={nanny.numberOfReferences != null ? t('nannies.referencesCount', { count: nanny.numberOfReferences }) : t('nannies.referencesCountOnly')}>
        {nanny.hasReferences === false || !nanny.references || nanny.references.length === 0 ? (
          <p className="text-[10px] font-semibold text-[#8090B0] mt-2">{t('nannies.noReferencesProvided')}</p>
        ) : (
          <div className="mt-2 flex flex-col gap-2">
            {nanny.references.map((ref, i) => (
              <div key={ref.id ?? i} className="rounded-lg border border-[#EBEEF8] p-2.5">
                <div className="flex items-center justify-between">
                  <div className="text-[10.5px] font-extrabold text-navy">{ref.relationship}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0]">
                    {ref.city}
                    {ref.yearsWorked ? ` · ${t('common.yearsShort', { count: ref.yearsWorked })}` : ''}
                  </div>
                </div>
                {ref.canConfirm && <div className="text-[9px] text-navy/70 mt-1">{t('nannies.canConfirm')}: {ref.canConfirm}</div>}
              </div>
            ))}
          </div>
        )}
      </Section>

      {nanny.introVideoUrl && (
        <Section title={t('nannies.introVideo')}>
          <video
            src={nanny.introVideoUrl}
            controls
            preload="metadata"
            className="w-full max-h-72 rounded-lg bg-black mt-2"
          />
          <div className="mt-1 flex items-center gap-2 flex-wrap">
            {nanny.introVideoStatus && (
              <StatusBadge variant={docVariant(nanny.introVideoStatus)}>
                {docStatusLabel(nanny.introVideoStatus)}
              </StatusBadge>
            )}
            <a
              href={nanny.introVideoUrl}
              target="_blank"
              rel="noreferrer"
              className="text-[9px] font-bold text-purple font-fredoka"
            >
              {t('common.openVideo')}
            </a>
            {onReviewVideo && (
              <div className="flex gap-1.5 ml-auto">
                {nanny.introVideoStatus !== 'approved' && (
                  <button
                    type="button"
                    className="qa-btn qa-g"
                    onClick={() => onReviewVideo('approved')}
                    disabled={videoBusy}
                  >
                    {t('nannies.approveVideo')}
                  </button>
                )}
                {nanny.introVideoStatus !== 'rejected' && (
                  <button
                    type="button"
                    className="qa-btn qa-r"
                    onClick={() => onReviewVideo('rejected')}
                    disabled={videoBusy}
                  >
                    {t('nannies.rejectVideo')}
                  </button>
                )}
              </div>
            )}
          </div>
        </Section>
      )}

      {nanny.stats && (
        <Section title={t('nannies.engagementStats')}>
          <FieldGrid>
            <Field label={t('nannies.profileViews')} value={String(nanny.stats.profileViews ?? 0)} />
            <Field label={t('nannies.shortlists')} value={String(nanny.stats.shortlists ?? 0)} />
            <Field label={t('nannies.applications')} value={String(nanny.stats.applicationsCount ?? 0)} />
            <Field label={t('nannies.trials')} value={String(nanny.stats.trialsCount ?? 0)} />
            <Field label={t('nannies.hires')} value={String(nanny.stats.hiresCount ?? 0)} />
          </FieldGrid>
        </Section>
      )}

      {showDocuments && (
        <Section title={t('nannies.documentsCountTitle', { count: nanny.documents?.length ?? 0 })}>
          <DocumentsGrid nanny={nanny} />
        </Section>
      )}
    </>
  );
}
