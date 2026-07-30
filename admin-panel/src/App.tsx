import { useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from './hooks/useAuth';
import Layout from './components/layout/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import AllNannies from './pages/nannies/AllNannies';
import VerifyDocuments from './pages/nannies/VerifyDocuments';
import VerifyVideos from './pages/nannies/VerifyVideos';
import NannyDetail from './pages/nannies/NannyDetail';
import AllFamilies from './pages/families/AllFamilies';
import Subscriptions from './pages/families/Subscriptions';
import FamilyDetail from './pages/families/FamilyDetail';
import Revenue from './pages/business/Revenue';
import Broadcast from './pages/business/Broadcast';
import Disputes from './pages/disputes/Disputes';
import DisputeDetail from './pages/disputes/DisputeDetail';
import SupportTickets from './pages/support/SupportTickets';
import SupportTicketDetail from './pages/support/SupportTicketDetail';
import AllTrials from './pages/trials/AllTrials';
import TrialDetail from './pages/trials/TrialDetail';
import Settings from './pages/Settings';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuthStore();
  if (loading) return <div className="flex items-center justify-center h-screen">Loading...</div>;
  if (!user) return <Navigate to="/login" replace />;
  if (!user.isAdmin) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  const init = useAuthStore((s) => s.init);
  useEffect(() => init(), [init]);

  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/*"
        element={
          <ProtectedRoute>
            <Layout>
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/nannies" element={<AllNannies />} />
                <Route path="/nannies/verify" element={<VerifyDocuments />} />
                <Route path="/nannies/verify-videos" element={<VerifyVideos />} />
                <Route path="/nannies/:id" element={<NannyDetail />} />
                <Route path="/families" element={<AllFamilies />} />
                <Route path="/families/subscriptions" element={<Subscriptions />} />
                <Route path="/families/:id" element={<FamilyDetail />} />
                <Route path="/trials" element={<AllTrials />} />
                <Route path="/trials/:id" element={<TrialDetail />} />
                <Route path="/disputes" element={<Disputes />} />
                <Route path="/disputes/:id" element={<DisputeDetail />} />
                <Route path="/support" element={<SupportTickets />} />
                <Route path="/support/:id" element={<SupportTicketDetail />} />
                <Route path="/revenue" element={<Revenue />} />
                <Route path="/broadcast" element={<Broadcast />} />
                <Route path="/settings" element={<Settings />} />
                {/* Unknown paths (typos, stale bookmarks, deleted-entity links)
                    redirect home instead of rendering a blank content area. */}
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Layout>
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}
