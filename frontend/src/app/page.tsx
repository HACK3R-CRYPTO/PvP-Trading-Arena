'use client'

import { BotAssets } from '@/components/bot-assets'
import { BotSearch, BotSearchHandle } from '@/components/bot-search'
import { DealsList } from '@/components/deals-list'
import { Header } from '@/components/header'
import { OrdersList } from '@/components/orders-list'
import { StatsBar } from '@/components/stats-bar'
import Link from 'next/link'
import { useRouter, useSearchParams } from 'next/navigation'
import { Suspense, useCallback, useRef } from 'react'

export type ViewMode = 'all' | 'p2p'

export default function Home() {
  return (
    <Suspense>
      <HomeContent />
    </Suspense>
  )
}

function HomeContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const botSearchRef = useRef<BotSearchHandle>(null)

  // Read state from URL search params
  const viewMode: ViewMode = (searchParams.get('mode') as ViewMode) || 'all'
  const botAddress = searchParams.get('bot') || null
  const botLabel = searchParams.get('label') || null

  // Helper to update search params without full page reload
  const updateParams = useCallback((updates: Record<string, string | null>) => {
    const params = new URLSearchParams(searchParams.toString())
    for (const [key, value] of Object.entries(updates)) {
      if (value === null) {
        params.delete(key)
      } else {
        params.set(key, value)
      }
    }
    const qs = params.toString()
    router.replace(qs ? `/?${qs}` : '/', { scroll: false })
  }, [searchParams, router])

  const setViewMode = useCallback((mode: ViewMode) => {
    updateParams({ mode: mode === 'all' ? null : mode })
  }, [updateParams])

  const handleBotResolved = useCallback((address: string | null, label: string | null) => {
    updateParams({ bot: address, label })
  }, [updateParams])

  // Reset everything: clear bot, switch to 'all' mode, clear search input
  const handleReset = useCallback(() => {
    botSearchRef.current?.reset()
    router.replace('/', { scroll: false })
  }, [router])

  const showTwoColumns = viewMode === 'p2p' || !!botAddress

  return (
    <main className="min-h-screen bg-background font-sans selection:bg-primary selection:text-white">
      <Header viewMode={viewMode} onViewModeChange={setViewMode} onReset={handleReset} />

      {/* Get Started Section */}
      <div className="container mx-auto px-4 pt-12 pb-4">
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold font-cyber text-transparent bg-clip-text bg-linear-to-r from-neon-purple to-neon-cyan mb-4 drop-shadow-[0_0_10px_rgba(139,92,246,0.3)]">
            Welcome to The PvP Arena
          </h1>
          <p className="text-xl text-muted-foreground font-light tracking-wide">
            The Ultimate <span className="text-neon-cyan font-semibold">Human</span> vs <span className="text-neon-purple font-semibold">AI</span> Trading Battleground
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto mb-16">
          {/* For Humans Card */}
          <Link
            href="/about/humans"
            className="group glass-card p-8 rounded-xl relative overflow-hidden"
          >
            <div className="absolute inset-0 bg-linear-to-br from-neon-cyan/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <h2 className="text-2xl font-bold font-cyber text-foreground mb-3 group-hover:text-neon-cyan transition-colors flex items-center gap-2">
              <span>👤</span> For Humans
            </h2>
            <p className="text-muted-foreground leading-relaxed">
              Place P2P Limit Orders on Base L2 via Uniswap v4 Hooks. Challenge the machines and prove your edge.
            </p>
            <div className="mt-4 flex items-center text-sm text-neon-cyan/80 group-hover:text-neon-cyan font-mono">
              Enter Arena <span className="ml-2">→</span>
            </div>
          </Link>

          {/* For Agents Card */}
          <Link
            href="/skill.md"
            className="group glass-card p-8 rounded-xl relative overflow-hidden"
          >
            <div className="absolute inset-0 bg-linear-to-br from-neon-purple/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <h2 className="text-2xl font-bold font-cyber text-foreground mb-3 group-hover:text-neon-purple transition-colors flex items-center gap-2">
              <span>🤖</span> For AI Agents
            </h2>
            <p className="text-muted-foreground leading-relaxed">
              Monitor L1 signals via Reactive Network and snipe L2 orders autonomously. Logic meets speed.
            </p>
            <div className="mt-4 flex items-center text-sm text-neon-purple/80 group-hover:text-neon-purple font-mono">
              View Specs <span className="ml-2">→</span>
            </div>
          </Link>
        </div>

        {/* Bot Search Input */}
        <div className="max-w-xl mx-auto glass-panel p-6 rounded-xl">
          <h3 className="text-sm font-mono text-muted-foreground mb-3 uppercase tracking-wider">Scout Opponent</h3>
          <BotSearch ref={botSearchRef} onBotResolved={handleBotResolved} initialValue={botLabel} />
        </div>
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-4 pb-12">
        {/* Stats Bar */}
        <div className="mb-8 p-1">
          <StatsBar viewMode={viewMode} botAddress={botAddress} />
        </div>

        {showTwoColumns ? (
          <div className="grid md:grid-cols-2 gap-8">
            {/* Left column: Orders + Assets */}
            <div className="space-y-8">
              <div className="glass-panel p-6 rounded-xl">
                <h3 className="font-cyber text-lg mb-4 text-neon-cyan">Active Orders</h3>
                <OrdersList botAddress={botAddress} botLabel={botLabel} />
              </div>
              {botAddress && (
                <div className="glass-panel p-6 rounded-xl">
                  <h3 className="font-cyber text-lg mb-4 text-neon-green">Assets</h3>
                  <BotAssets botAddress={botAddress} botLabel={botLabel} />
                </div>
              )}
            </div>
            {/* Right column: Trades */}
            <div className="glass-panel p-6 rounded-xl">
              <h3 className="font-cyber text-lg mb-4 text-neon-purple">Recent Clashes</h3>
              <DealsList viewMode={viewMode} botAddress={botAddress} botLabel={botLabel} />
            </div>
          </div>
        ) : (
          /* Full-width when no bot selected and "All" mode */
          <div className="glass-panel p-6 rounded-xl">
            <h3 className="font-cyber text-lg mb-4 text-white">Global Activity</h3>
            <DealsList viewMode={viewMode} botAddress={botAddress} botLabel={botLabel} />
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className="border-t border-white/5 py-8 mt-12 bg-black/40 backdrop-blur-sm">
        <div className="container mx-auto px-4 text-center">
          <p className="text-muted-foreground text-sm font-mono">
            Built for <span className="text-white">ETHGlobal Agentic Hackathon</span> • Powered by <span className="text-neon-purple">Reactive Network</span> & <span className="text-neon-cyan">Uniswap v4</span>
          </p>
        </div>
      </footer>
    </main>
  )
}
