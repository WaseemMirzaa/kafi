import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Avatar,
  ColStat,
  PageContent,
  PageHeader,
  PageShell,
  Row,
  StatusBadge,
  TableCard,
  PageLoader,
} from '../../components/ui/AdminUI';
import { FamilyService, FamilyRow } from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { exportCsv } from '../../utils/csv';
import { useLocale } from '../../context/LocaleContext';
import { TranslationKey } from '../../locales/t';
import { subscriptionPlanLabel } from '../../utils/nannyLabels';

const statusVariant: Record<string, string> = {
  active: 'sub',
  cancelled: 'sub',
  free: 'unsub',
  expired: 'expired',
  paymentFailed: 'expired',
};

const statusLabelKeys: Record<string, TranslationKey> = {
  active: 'families.subscriptionStatus.active',
  cancelled: 'families.subscriptionStatus.cancelled',
  free: 'families.subscriptionStatus.free',
  expired: 'families.subscriptionStatus.expired',
  paymentFailed: 'families.subscriptionStatus.paymentFailed',
};

export default function AllFamilies() {
  const { t } = useLocale();
  const [items, setItems] = useState<FamilyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    setLoadError(null);
    FamilyService.list()
      .then(setItems)
      .catch((e) => setLoadError((e as Error).message || t('families.failedToLoad')))
      .finally(() => setLoading(false));
  }, [t]);

  const toggleBlock = async (f: FamilyRow) => {
    setBusyId(f.id);
    try {
      if (f.blocked) {
        await FamilyService.unblock(f.id);
      } else {
        await FamilyService.block(f.id);
      }
      setItems((prev) => prev.map((x) => x.id === f.id ? { ...x, blocked: !x.blocked } : x));
    } catch (e) {
      // Without this the failure was swallowed — the admin assumed the block
      // took when it didn't. Surface it (NannyDetail uses the same alert).
      alert((e as Error).message || t('families.blockToggleFailed'));
    } finally {
      setBusyId(null);
    }
  };

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return items;
    return items.filter((f) =>
      [f.fullName, f.nationality, f.city].some((s) => s?.toLowerCase().includes(q))
    );
  }, [items, search]);

  const subscribed = items.filter((f) => ['active', 'cancelled'].includes(f.subscription.status)).length;
  const free = items.filter((f) => f.subscription.status === 'free').length;
  const expired = items.filter((f) => ['expired', 'paymentFailed'].includes(f.subscription.status)).length;

  const onExport = () => {
    exportCsv('families.csv', filtered, [
      { header: 'ID', value: (r) => r.id },
      { header: 'Name', value: (r) => r.fullName },
      { header: 'Nationality', value: (r) => r.nationality },
      { header: 'City', value: (r) => r.city },
      { header: 'Status', value: (r) => r.subscription.status },
      { header: 'Plan', value: (r) => r.subscription.plan ?? '' },
      { header: 'EndDate', value: (r) => r.subscription.endDate?.toISOString() ?? '' },
      { header: 'FreeContactsUsed', value: (r) => String(r.freeContactsUsed ?? 0) },
    ]);
  };

  return (
    <PageShell>
      <PageHeader
        title={t('families.allFamiliesTitle')}
        subtitle={t('families.allFamiliesSubtitle', { count: items.length })}
        actions={
          <>
            <input
              type="search"
              placeholder={t('families.searchPlaceholder')}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-card text-[10px] font-semibold text-navy px-3 py-2 w-52 border-[#EBEEF8] focus:outline-none"
            />
            <button type="button" className="qa-btn qa-g" onClick={onExport}>
              {t('common.exportCsv')}
            </button>
          </>
        }
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(subscribed)} label={t('families.subscribed')} change={t('families.liveChange')} />
          <ColStat num={String(free)} label={t('families.freeUsers')} change={t('dashboard.convert')} numColor="#8090B0" />
          <ColStat num={String(expired)} label={t('families.expired')} change={t('families.reactivate')} numColor="#FF5C8A" />
        </div>

        <TableCard title={t('families.familyAccounts')}>
          {loading && <PageLoader compact />}
          {!loading && loadError && (
            <div className="px-3 py-4 text-[10px] font-bold text-rose-dark">{loadError}</div>
          )}
          {!loading && !loadError && filtered.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">{t('families.noneFound')}</div>
          )}
          {filtered.map((f) => (
            <Row key={f.id}>
              <Avatar letter={initials(f.fullName)} gradient={gradientFor(f.id)} />
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy">
                  {f.fullName}
                  {f.blocked && <span className="ml-1.5 text-[8px] font-bold text-rose-dark">{t('nannies.blocked')}</span>}
                </div>
                <div className="text-[8.5px] font-semibold text-[#8090B0]">
                  {f.nationality} · {f.city}
                  {f.subscription.plan ? ` · ${subscriptionPlanLabel(f.subscription.plan)}` : ''}
                </div>
              </div>
              <div className="flex flex-col items-end gap-0.5">
                <StatusBadge variant={statusVariant[f.subscription.status] ?? 'pending'}>
                  {statusLabelKeys[f.subscription.status] ? t(statusLabelKeys[f.subscription.status]) : f.subscription.status}
                </StatusBadge>
                {(f.activeTrialNannyIds?.length ?? 0) > 0 && (
                  <span className="text-[8px] font-bold text-purple">{t('families.trialActive')}</span>
                )}
              </div>
              <button
                type="button"
                className={`text-[8.5px] font-bold px-2 py-0.5 rounded-md ml-1 ${f.blocked ? 'bg-green-pale text-green-dark' : 'bg-rose-pale text-rose-dark'}`}
                disabled={busyId === f.id}
                onClick={() => toggleBlock(f)}
              >
                {f.blocked ? t('common.unblock') : t('common.block')}
              </button>
              <Link to={`/families/${f.id}`} className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1">
                {t('common.view')}
              </Link>
            </Row>
          ))}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
