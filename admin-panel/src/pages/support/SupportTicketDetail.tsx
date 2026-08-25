import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
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
import { MessageThread, ThreadMessage } from '../../components/chat/MessageThread';
import { TicketService, TicketRow, TicketMessageRow } from '../../services/firestore';
import { useLocale } from '../../context/LocaleContext';
import { t as translate, TranslationKey } from '../../locales/t';
import { ticketStatusLabel, personTypeLabel } from '../../utils/nannyLabels';

const categoryLabelKeys: Record<TicketRow['category'], TranslationKey> = {
  account: 'support.category.account',
  payment: 'support.category.payment',
  trial: 'support.category.trial',
  hiring: 'support.category.hiring',
  technical: 'support.category.technical',
  other: 'support.category.other',
};

const statusVariant: Record<TicketRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  closed: 'rejected',
};

const STATUSES: TicketRow['status'][] = ['open', 'investigating', 'resolved', 'closed'];

function toThreadMessages(msgs: TicketMessageRow[]): ThreadMessage[] {
  return msgs.map((m) => ({
    id: m.id,
    align: m.senderType === 'admin' ? 'right' : 'left',
    author: m.senderName ?? (m.senderType === 'admin' ? translate('chat.supportSender') : translate('chat.userSender')),
    content: m.content,
    timestamp: m.createdAt,
  }));
}

export default function SupportTicketDetail() {
  const { t } = useLocale();
  const { id } = useParams();
  const [ticket, setTicket] = useState<TicketRow | null>(null);
  const [messages, setMessages] = useState<TicketMessageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  // Live ticket doc + messages so nanny/family replies and status changes
  // appear without a manual refresh.
  useEffect(() => {
    if (!id) return;
    setLoading(true);
    setError(null);
    let gotDoc = false;
    let gotMsgs = false;
    const markReady = () => {
      if (gotDoc && gotMsgs) setLoading(false);
    };
    const unsubDoc = TicketService.watch(
      id,
      (tk) => {
        setTicket(tk);
        gotDoc = true;
        markReady();
      },
      (e) => {
        setError(e.message || t('support.failedToLoadTicket'));
        gotDoc = true;
        markReady();
      },
    );
    const unsubMsgs = TicketService.watchMessages(
      id,
      (m) => {
        setMessages(m);
        gotMsgs = true;
        markReady();
      },
      (e) => {
        setError(e.message || t('support.failedToLoadTicket'));
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
  if (error && !ticket) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] font-bold text-rose-dark">{error}</div>
        </PageContent>
      </PageShell>
    );
  }
  if (!ticket) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">{t('common.notFound')}</div>
        </PageContent>
      </PageShell>
    );
  }

  const send = async (text: string) => {
    setSending(true);
    setActionError(null);
    try {
      await TicketService.sendMessage(ticket.id, text);
    } catch (e) {
      setActionError((e as Error).message || t('support.failedToSendReply'));
    } finally {
      setSending(false);
    }
  };

  const setStatus = async (status: TicketRow['status']) => {
    setBusy(true);
    setActionError(null);
    try {
      await TicketService.updateStatus(ticket.id, status);
    } catch (e) {
      setActionError((e as Error).message || t('support.failedToUpdateStatus'));
    } finally {
      setBusy(false);
    }
  };

  const closed = ticket.status === 'resolved' || ticket.status === 'closed';

  return (
    <PageShell>
      <PageHeader
        title={ticket.subject || t('support.ticketFallback')}
        subtitle={t('support.hash', { id: ticket.id })}
        actions={
          <QaLink to="/support" variant="n">
            {t('support.allTicketsLink')}
          </QaLink>
        }
      />
      <PageContent>
        <DetailCard>
          <div className="flex items-center gap-2">
            <div className="text-[12px] font-black text-navy">{t(categoryLabelKeys[ticket.category])}</div>
            <StatusBadge variant={statusVariant[ticket.status]}>{ticketStatusLabel(ticket.status)}</StatusBadge>
            <div className="flex-1 min-w-0 text-[8.5px] font-semibold text-[#8090B0] truncate">
              {ticket.openerName ?? ticket.openerId} ({personTypeLabel(ticket.openerType)}) · {ticket.createdAt.toLocaleDateString()}
            </div>
          </div>
          <FieldGrid>
            <Field label={t('support.openedBy')} value={`${ticket.openerName ?? ticket.openerId} (${personTypeLabel(ticket.openerType)})`} />
            <Field label={t('support.category')} value={t(categoryLabelKeys[ticket.category])} />
            <Field label={t('support.relatedTrial')} value={ticket.relatedTrialId ?? t('common.dash')} />
            <Field label={t('support.openedOn')} value={ticket.createdAt.toLocaleDateString()} />
          </FieldGrid>
        </DetailCard>

        {actionError && (
          <div className="text-[10px] font-bold text-rose-dark">{actionError}</div>
        )}

        <Section title={t('support.conversation')}>
          <p className="text-[9px] font-semibold text-[#8090B0] mb-1">
            {t('support.conversationWith', { name: ticket.openerName ?? t('support.theUser') })}
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
              {t('support.ticketStatusClosed', { status: ticketStatusLabel(ticket.status) })}
            </div>
          )}
        </Section>

        <Section title={t('support.statusSection')}>
          <div className="flex flex-wrap gap-1.5 mt-2">
            {STATUSES.map((s) => (
              <button
                key={s}
                type="button"
                className={`qa-btn ${ticket.status === s ? 'qa-p' : 'qa-n'}`}
                disabled={busy}
                onClick={() => setStatus(s)}
              >
                {ticketStatusLabel(s)}
              </button>
            ))}
          </div>
        </Section>
      </PageContent>
    </PageShell>
  );
}
