import { useEffect, useMemo, useState } from 'react';
import {
  Avatar,
  ColStat,
  PageContent,
  PageHeader,
  PageShell,
  QaLink,
  Row,
  StatusBadge,
  TableCard,
} from '../../components/ui/AdminUI';
import { NannyService, NannyRow } from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { useAuthStore } from '../../hooks/useAuth';
import { NannyProfileView } from '../../components/nanny/NannyProfileView';
import { DocThumb } from '../../components/nanny/DocFilePreview';
import { FilterBar, FilterSelect, Pagination } from '../../components/ui/ListControls';
import { useListControls } from '../../hooks/useListControls';

const DOC_STATUSES = ['approved', 'rejected', 'resubmitted', 'uploaded', 'pending', 'missing'];

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

export default function VerifyDocuments() {
  const [items, setItems] = useState<NannyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [rejectFor, setRejectFor] = useState<NannyRow | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [docRejectFor, setDocRejectFor] = useState<{ nanny: NannyRow; docType: string } | null>(null);
  const [docRejectReason, setDocRejectReason] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);
  const [docStatus, setDocStatus] = useState('all');
  // Popup state: the nanny whose documents are being viewed, and whether the
  // popup is currently showing the full profile instead of the document list.
  const [docsFor, setDocsFor] = useState<NannyRow | null>(null);
  const [showProfile, setShowProfile] = useState(false);
  // Sensitive KYC download URLs now live in the private
  // nannies/{id}/documents subcollection (C5) — fetched on demand when a
  // nanny's documents are opened, keyed by document type.
  const [docUrls, setDocUrls] = useState<Record<string, string>>({});
  const { user } = useAuthStore();

  const reload = async (): Promise<NannyRow[]> => {
    setLoading(true);
    setError(null);
    try {
      // Use the pending-docs query so we don't pull every approved nanny.
      const all = await NannyService.listPendingDocs();
      setItems(all);
      return all;
    } catch (e) {
      setError((e as Error).message || 'Failed to load nannies');
      return [];
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  // Keep the open popup in sync with refreshed data (closes it if the nanny is
  // no longer pending, e.g. after approving every document).
  const syncDocsFor = (all: NannyRow[]) => {
    setDocsFor((prev) => (prev ? all.find((n) => n.id === prev.id) ?? null : null));
  };

  const openDocs = async (n: NannyRow) => {
    setShowProfile(false);
    setDocsFor(n);
    setDocUrls({});
    try {
      setDocUrls(await NannyService.getDocumentUrls(n.id));
    } catch {
      // Non-fatal — the approve/reject actions work without the previews.
    }
  };
  const closeDocs = () => {
    setDocsFor(null);
    setShowProfile(false);
  };

  // `items` already holds only pending nannies (listPendingDocs).
  const pending = items;
  const approved = 0; // approved & rejected counts handled in AllNannies tab.
  const rejected = 0;

  const extraFilter = useMemo(
    () => (n: NannyRow) =>
      docStatus === 'all' || (n.documents ?? []).some((d) => d.status === docStatus),
    [docStatus],
  );

  const lc = useListControls(items, {
    search: (n, q) => [n.fullName, n.nationality, n.city].some((s) => s?.toLowerCase().includes(q)),
    getDate: (n) => n.createdAt,
    extraFilter,
    pageSize: 6,
  });

  const approve = async (n: NannyRow) => {
    setBusyId(n.id);
    try {
      await NannyService.approve(n.id, user?.uid ?? 'unknown');
      const all = await reload();
      syncDocsFor(all);
    } catch (e) {
      alert((e as Error).message || 'Approve failed');
    } finally {
      setBusyId(null);
    }
  };

  const submitReject = async () => {
    if (!rejectFor || !rejectReason.trim()) return;
    setBusyId(rejectFor.id);
    try {
      await NannyService.reject(rejectFor.id, rejectReason.trim(), user?.uid ?? 'unknown');
      const closeId = rejectFor.id;
      setRejectFor(null);
      setRejectReason('');
      const all = await reload();
      // closing the rejected nanny's popup if it was open
      if (docsFor?.id === closeId) closeDocs();
      else syncDocsFor(all);
    } catch (e) {
      alert((e as Error).message || 'Reject failed');
    } finally {
      setBusyId(null);
    }
  };

  const approveDoc = async (n: NannyRow, docType: string) => {
    setBusyId(`${n.id}:${docType}`);
    try {
      await NannyService.reviewDocument(n.id, docType, 'approved');
      const all = await reload();
      syncDocsFor(all);
    } catch (e) {
      alert((e as Error).message || 'Approve doc failed');
    } finally {
      setBusyId(null);
    }
  };

  const submitDocReject = async () => {
    if (!docRejectFor || !docRejectReason.trim()) return;
    setBusyId(`${docRejectFor.nanny.id}:${docRejectFor.docType}`);
    try {
      await NannyService.reviewDocument(
        docRejectFor.nanny.id,
        docRejectFor.docType,
        'rejected',
        docRejectReason.trim(),
      );
      setDocRejectFor(null);
      setDocRejectReason('');
      const all = await reload();
      syncDocsFor(all);
    } catch (e) {
      alert((e as Error).message || 'Reject doc failed');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <PageShell>
      <PageHeader
        title="Verify documents"
        subtitle={`${pending.length} documents pending review`}
        actions={
          <QaLink to="/nannies" variant="n">
            All nannies
          </QaLink>
        }
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(pending.length)} label="Pending" change="⚠ Review" numColor="#FFB347" />
          <ColStat num={String(approved)} label="Approved" change="↑ Verified" />
          <ColStat num={String(rejected)} label="Rejected" change="Re-upload" numColor="#FF5C8A" />
        </div>

        <FilterBar
          query={lc.query}
          setQuery={lc.setQuery}
          from={lc.from}
          setFrom={lc.setFrom}
          to={lc.to}
          setTo={lc.setTo}
          onClear={() => {
            lc.clear();
            setDocStatus('all');
          }}
          searchPlaceholder="Search by name, nationality, city…"
          dateLabel="Submitted"
        >
          <FilterSelect
            label="Document status"
            value={docStatus}
            onChange={setDocStatus}
            options={[{ value: 'all', label: 'All documents' }, ...DOC_STATUSES.map((s) => ({ value: s, label: s }))]}
          />
        </FilterBar>

        <TableCard title="Document verification queue">
          {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
          {!loading && lc.total === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">
              {pending.length === 0 ? 'All caught up — no pending docs.' : 'No nannies match your filters.'}
            </div>
          )}
          {lc.pageItems.map((d) => (
            <Row key={d.id}>
              <Avatar letter={initials(d.fullName)} gradient={gradientFor(d.id)} />
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy">{d.fullName}</div>
                <div className="text-[8.5px] font-semibold text-[#8090B0]">
                  {d.nationality} · {d.city} · {(d.documents ?? []).length} documents
                </div>
              </div>
              <StatusBadge variant="verify">Needs review</StatusBadge>
              <button type="button" className="qa-btn qa-p" onClick={() => openDocs(d)}>
                View →
              </button>
            </Row>
          ))}
          <Pagination
            page={lc.page}
            pageCount={lc.pageCount}
            rangeStart={lc.rangeStart}
            rangeEnd={lc.rangeEnd}
            total={lc.total}
            onPage={lc.setPage}
          />
        </TableCard>

        {error && (
          <div className="mt-2 p-2 bg-rose-pale text-rose-dark text-[10px] font-bold rounded-lg">{error}</div>
        )}

        {/* ── Documents popup ── */}
        {docsFor && (
          <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center px-4 py-6">
            <div className="admin-card w-full max-w-2xl max-h-[88vh] flex flex-col overflow-hidden">
              {/* Header */}
              <div className="flex items-center gap-2.5 px-4 py-3 border-b border-[#EBEEF8]">
                <Avatar letter={initials(docsFor.fullName)} gradient={gradientFor(docsFor.id)} />
                <div className="flex-1 min-w-0">
                  <div className="text-[12px] font-black text-navy truncate">{docsFor.fullName}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                    {docsFor.nationality} · {docsFor.city}
                  </div>
                </div>
                {showProfile ? (
                  <button type="button" className="qa-btn qa-n" onClick={() => setShowProfile(false)}>
                    ← Documents
                  </button>
                ) : (
                  <button type="button" className="qa-btn qa-p" onClick={() => setShowProfile(true)}>
                    View full profile
                  </button>
                )}
                <button
                  type="button"
                  className="text-[16px] font-bold text-[#8090B0] hover:text-navy px-1"
                  onClick={closeDocs}
                  aria-label="Close"
                >
                  ×
                </button>
              </div>

              {/* Body */}
              <div className="flex-1 overflow-y-auto px-4 py-3">
                {showProfile ? (
                  <NannyProfileView nanny={docsFor} showDocuments={false} />
                ) : (
                  <>
                    <div className="text-[9px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">
                      Submitted documents ({(docsFor.documents ?? []).length})
                    </div>
                    {(docsFor.documents ?? []).length === 0 ? (
                      <div className="text-[10px] text-[#8090B0]">No documents uploaded.</div>
                    ) : (
                      <div className="flex flex-col gap-2">
                        {(docsFor.documents ?? []).map((doc) => {
                          const docBusyKey = `${docsFor.id}:${doc.type}`;
                          // Prefer the inline url (mock / legacy data), else the
                          // one fetched from the private documents subcollection.
                          const docUrl = doc.url ?? docUrls[doc.type];
                          return (
                            <div
                              key={doc.type}
                              className="flex items-center gap-3 rounded-lg border border-[#EBEEF8] p-2"
                            >
                              <DocThumb url={docUrl} label={docLabel[doc.type] ?? doc.type} />
                              <div className="flex-1 min-w-0">
                                <div className="text-[10.5px] font-extrabold text-navy">
                                  {docLabel[doc.type] ?? doc.type}
                                </div>
                                {doc.rejectionReason && (
                                  <div className="text-[8.5px] font-semibold text-rose-dark mt-0.5">
                                    {doc.rejectionReason}
                                  </div>
                                )}
                                {docUrl && (
                                  <a
                                    href={docUrl}
                                    target="_blank"
                                    rel="noreferrer"
                                    className="text-[8.5px] font-bold text-purple font-fredoka"
                                  >
                                    Open file ↗
                                  </a>
                                )}
                              </div>
                              <StatusBadge variant={docVariant(doc.status)}>{doc.status}</StatusBadge>
                              {doc.status !== 'approved' && (
                                <div className="flex gap-1">
                                  <button
                                    type="button"
                                    className="verify-btn"
                                    disabled={busyId === docBusyKey}
                                    onClick={() => approveDoc(docsFor, doc.type)}
                                  >
                                    ✓
                                  </button>
                                  <button
                                    type="button"
                                    className="reject-btn"
                                    disabled={busyId === docBusyKey}
                                    onClick={() => setDocRejectFor({ nanny: docsFor, docType: doc.type })}
                                  >
                                    ✗
                                  </button>
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </>
                )}
              </div>

              {/* Footer */}
              <div className="flex items-center justify-end gap-1.5 px-4 py-3 border-t border-[#EBEEF8]">
                <button
                  type="button"
                  className="qa-btn qa-g"
                  disabled={busyId === docsFor.id}
                  onClick={() => approve(docsFor)}
                >
                  Approve all ✓
                </button>
                <button
                  type="button"
                  className="qa-btn qa-r"
                  disabled={busyId === docsFor.id}
                  onClick={() => setRejectFor(docsFor)}
                >
                  Reject all ✗
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ── Single-document rejection (stacks above the documents popup) ── */}
        {docRejectFor && (
          <div className="fixed inset-0 bg-black/40 z-[60] flex items-center justify-center px-4">
            <div className="admin-card p-4 max-w-sm w-full">
              <div className="text-[12px] font-black text-navy">
                Reject {docLabel[docRejectFor.docType] ?? docRejectFor.docType} for {docRejectFor.nanny.fullName}
              </div>
              <div className="text-[9px] font-semibold text-[#8090B0] mt-1 mb-3">
                Tell the nanny why this document was rejected.
              </div>
              <textarea
                rows={4}
                value={docRejectReason}
                onChange={(e) => setDocRejectReason(e.target.value)}
                placeholder="e.g. Document is blurry, please re-upload a clear copy."
                className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30 resize-none"
              />
              <div className="flex justify-end gap-1.5 mt-3">
                <button type="button" className="qa-btn qa-n" onClick={() => setDocRejectFor(null)}>
                  Cancel
                </button>
                <button
                  type="button"
                  className="qa-btn qa-r"
                  onClick={submitDocReject}
                  disabled={!docRejectReason.trim()}
                >
                  Reject document
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ── Whole-profile rejection ── */}
        {rejectFor && (
          <div className="fixed inset-0 bg-black/40 z-[60] flex items-center justify-center px-4">
            <div className="admin-card p-4 max-w-sm w-full">
              <div className="text-[12px] font-black text-navy">Reject {rejectFor.fullName}</div>
              <div className="text-[9px] font-semibold text-[#8090B0] mt-1 mb-3">
                Provide a clear reason — the nanny will see this in-app.
              </div>
              <textarea
                rows={4}
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="e.g. Emirates ID photo is blurry, please re-upload a clear copy."
                className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30 resize-none"
              />
              <div className="flex justify-end gap-1.5 mt-3">
                <button type="button" className="qa-btn qa-n" onClick={() => setRejectFor(null)}>
                  Cancel
                </button>
                <button
                  type="button"
                  className="qa-btn qa-r"
                  onClick={submitReject}
                  disabled={!rejectReason.trim() || busyId === rejectFor.id}
                >
                  Send rejection
                </button>
              </div>
            </div>
          </div>
        )}
      </PageContent>
    </PageShell>
  );
}
