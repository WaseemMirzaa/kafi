import { NannyRow } from '../../services/firestore';
import { Field, FieldGrid, StatusBadge } from '../ui/AdminUI';
import { DocViewer } from './DocFilePreview';
import {
  visaStatusLabel,
  availabilityLabel,
  jobTypeLabel,
  maritalStatusLabel,
  label,
  yesNo,
  salaryRange,
  emiratesList,
  listOr,
  formatDate,
} from '../../utils/nannyLabels';

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

const docLabel: Record<string, string> = {
  passport: 'Passport',
  visa: 'Visa',
  emiratesId: 'Emirates ID',
  trainingCert: 'Training certificate',
  policeClearance: 'Police clearance',
};

function docVariant(status: string): string {
  if (status === 'approved') return 'verified';
  if (status === 'rejected' || status === 'missing') return 'rejected';
  if (status === 'resubmitted') return 'new';
  return 'verify';
}

/** Read-only document grid — renders images, videos, PDFs and other formats. */
export function DocumentsGrid({ nanny }: { nanny: NannyRow }) {
  const docs = nanny.documents ?? [];
  if (docs.length === 0) {
    return <div className="text-[10px] text-[#8090B0] mt-2">No documents uploaded.</div>;
  }
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-3">
      {docs.map((doc, i) => (
        <div key={doc.type + i} className="rounded-lg border border-[#EBEEF8] overflow-hidden">
          <div className="p-2">
            <DocViewer url={doc.url} label={docLabel[doc.type] ?? doc.type} />
          </div>
          <div className="flex items-center justify-between gap-1 px-2 py-1.5 border-t border-[#EBEEF8]">
            <div className="text-[9px] font-extrabold text-navy truncate">{docLabel[doc.type] ?? doc.type}</div>
            <StatusBadge variant={docVariant(doc.status)}>{doc.status}</StatusBadge>
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
  return (
    <>
      {nanny.bio && (
        <Section title="About">
          <p className="text-[10.5px] font-semibold text-navy/80 leading-relaxed mt-2">{nanny.bio}</p>
        </Section>
      )}

      {(nanny.photoUrls?.length || 0) > 0 && (
        <Section title={`Photos (${nanny.photoUrls!.length})`}>
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

      <Section title="Personal & demographics">
        <FieldGrid>
          <Field label="Full name" value={nanny.fullName || '—'} />
          <Field label="Nationality" value={nanny.nationality || '—'} />
          <Field label="Date of birth" value={formatDate(nanny.dateOfBirth)} />
          <Field label="Age" value={nanny.age ? `${nanny.age}` : '—'} />
          <Field label="City" value={nanny.city || '—'} />
          <Field label="Current area" value={nanny.currentArea || '—'} />
          <Field label="Marital status" value={label(maritalStatusLabel, nanny.maritalStatus)} />
          <Field label="Has children" value={yesNo(nanny.hasChildren)} />
          <Field label="Number of children" value={nanny.childrenCount != null ? String(nanny.childrenCount) : '—'} />
          <Field label="Children's ages" value={nanny.childrenAges || '—'} />
        </FieldGrid>
      </Section>

      <Section title="Languages & communication">
        <FieldGrid>
          <Field label="Languages" value={listOr(nanny.languages)} />
        </FieldGrid>
      </Section>

      <Section title="Visa & Emirates ID">
        <FieldGrid>
          <Field label="Visa status" value={label(visaStatusLabel, nanny.visaStatus)} />
          <Field label="Has Emirates ID" value={yesNo(nanny.hasEmiratesId)} />
          <Field label="Emirates ID number" value={nanny.eidNumber || '—'} />
          <Field label="Willing to transfer visa" value={yesNo(nanny.willingToTransferVisa)} />
        </FieldGrid>
      </Section>

      <Section title="Work location & availability">
        <FieldGrid>
          <Field label="Work emirates" value={emiratesList(nanny.workEmirates)} />
          <Field label="Willing to relocate" value={yesNo(nanny.willingToRelocate)} />
          <Field label="Availability" value={label(availabilityLabel, nanny.availability)} />
          <Field label="Available from" value={formatDate(nanny.availableFrom)} />
        </FieldGrid>
      </Section>

      <Section title="Job preferences & compensation">
        <FieldGrid>
          <Field label="Job type preference" value={label(jobTypeLabel, nanny.jobTypePreference)} />
          <Field label="Expected salary" value={salaryRange(nanny.expectedSalaryMin, nanny.expectedSalaryMax)} />
          <Field label="Can do night shifts" value={yesNo(nanny.canDoNightShifts)} />
        </FieldGrid>
      </Section>

      <Section title="Skills & household preferences">
        <FieldGrid>
          <Field label="Can cook" value={yesNo(nanny.canCook)} />
          <Field label="Cuisines" value={listOr(nanny.cuisines)} />
          <Field label="Comfortable with pets" value={yesNo(nanny.comfortableWithPets)} />
          <Field label="Pet types" value={listOr(nanny.petTypes)} />
          <Field label="Comfortable with cameras" value={yesNo(nanny.comfortableWithCameras)} />
          <Field label="Camera note" value={nanny.cameraNote || '—'} />
        </FieldGrid>
      </Section>

      <Section title="Health">
        <FieldGrid>
          <Field label="Has health conditions" value={yesNo(nanny.hasHealthConditions)} />
          <Field label="Health conditions" value={nanny.healthConditions || '—'} />
          <Field label="Takes medication" value={yesNo(nanny.takesMedication)} />
          <Field label="Medications" value={nanny.medications || '—'} />
          <Field label="Has allergies" value={yesNo(nanny.hasAllergies)} />
          <Field label="Allergies" value={nanny.allergies || '—'} />
        </FieldGrid>
      </Section>

      <Section title="Religion & cultural">
        <FieldGrid>
          <Field label="Religion" value={nanny.religion || '—'} />
          <Field label="Religious notes" value={nanny.religiousNotes || '—'} />
          <Field label="Comfortable with different faith" value={yesNo(nanny.comfortableWithDifferentFaith)} />
        </FieldGrid>
      </Section>

      <Section title="Emergency contact">
        <FieldGrid>
          <Field label="Name" value={nanny.emergencyName || '—'} />
          <Field label="Relationship" value={nanny.emergencyRelationship || '—'} />
          <Field label="Phone" value={nanny.emergencyPhone || '—'} />
        </FieldGrid>
      </Section>

      {nanny.experiences && nanny.experiences.length > 0 && (
        <Section title={`Work experience (${nanny.experiences.length})`}>
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
                {exp.children && <div className="text-[9px] text-navy/70 mt-1">Children: {exp.children}</div>}
                {exp.duties && <div className="text-[9px] text-navy/70 mt-0.5">Duties: {exp.duties}</div>}
                {exp.reasonLeaving && (
                  <div className="text-[9px] text-navy/70 mt-0.5">Reason for leaving: {exp.reasonLeaving}</div>
                )}
              </div>
            ))}
          </div>
        </Section>
      )}

      <Section title={`References${nanny.numberOfReferences != null ? ` (${nanny.numberOfReferences})` : ''}`}>
        {nanny.hasReferences === false || !nanny.references || nanny.references.length === 0 ? (
          <p className="text-[10px] font-semibold text-[#8090B0] mt-2">No references provided.</p>
        ) : (
          <div className="mt-2 flex flex-col gap-2">
            {nanny.references.map((ref, i) => (
              <div key={ref.id ?? i} className="rounded-lg border border-[#EBEEF8] p-2.5">
                <div className="flex items-center justify-between">
                  <div className="text-[10.5px] font-extrabold text-navy">{ref.relationship}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0]">
                    {ref.city}
                    {ref.yearsWorked ? ` · ${ref.yearsWorked} yrs` : ''}
                  </div>
                </div>
                {ref.canConfirm && <div className="text-[9px] text-navy/70 mt-1">Can confirm: {ref.canConfirm}</div>}
              </div>
            ))}
          </div>
        )}
      </Section>

      {nanny.introVideoUrl && (
        <Section title="Intro video">
          <video
            src={nanny.introVideoUrl}
            controls
            preload="metadata"
            className="w-full max-h-72 rounded-lg bg-black mt-2"
          />
          <div className="mt-1 flex items-center gap-2 flex-wrap">
            {nanny.introVideoStatus && (
              <StatusBadge variant={docVariant(nanny.introVideoStatus)}>
                {nanny.introVideoStatus}
              </StatusBadge>
            )}
            <a
              href={nanny.introVideoUrl}
              target="_blank"
              rel="noreferrer"
              className="text-[9px] font-bold text-purple font-fredoka"
            >
              Open video ↗
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
                    Approve video ✓
                  </button>
                )}
                {nanny.introVideoStatus !== 'rejected' && (
                  <button
                    type="button"
                    className="qa-btn qa-r"
                    onClick={() => onReviewVideo('rejected')}
                    disabled={videoBusy}
                  >
                    Reject video ✗
                  </button>
                )}
              </div>
            )}
          </div>
        </Section>
      )}

      {nanny.stats && (
        <Section title="Engagement stats">
          <FieldGrid>
            <Field label="Profile views" value={String(nanny.stats.profileViews ?? 0)} />
            <Field label="Shortlists" value={String(nanny.stats.shortlists ?? 0)} />
            <Field label="Applications" value={String(nanny.stats.applicationsCount ?? 0)} />
            <Field label="Trials" value={String(nanny.stats.trialsCount ?? 0)} />
            <Field label="Hires" value={String(nanny.stats.hiresCount ?? 0)} />
          </FieldGrid>
        </Section>
      )}

      {showDocuments && (
        <Section title={`Documents (${nanny.documents?.length ?? 0})`}>
          <DocumentsGrid nanny={nanny} />
        </Section>
      )}
    </>
  );
}
