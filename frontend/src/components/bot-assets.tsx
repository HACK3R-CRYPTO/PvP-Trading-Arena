'use client'

import { api } from '@/lib/api'
import { useEffect, useState } from 'react'

interface Asset {
  chainId: number
  symbol: string
  name: string
  amountFormatted: string
  priceUSD: string
  valueUSD: number
  logoURI?: string
}

interface BotAssetsProps {
  botAddress: string | null
  botLabel?: string | null
}

const CHAIN_NAMES: Record<number, string> = {
  1: 'Ethereum',
  10: 'Optimism',
  56: 'BNB Chain',
  100: 'Gnosis',
  137: 'Polygon',
  250: 'Fantom',
  8453: 'Base',
  42161: 'Arbitrum',
  43114: 'Avalanche',
  11155111: 'Sepolia',
  84532: 'Base Sepolia',
}

export function BotAssets({ botAddress, botLabel }: BotAssetsProps) {
  const [assets, setAssets] = useState<Asset[]>([])
  const [totalUSD, setTotalUSD] = useState(0)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!botAddress) {
      setAssets([])
      setTotalUSD(0)
      return
    }

    async function fetchAssets() {
      setLoading(true)
      setError(null)
      try {
        const res = await api.get(`/api/bots/assets/${botAddress}`)
        setAssets(res.data.assets || [])
        setTotalUSD(res.data.totalUSD || 0)
      } catch (err: any) {
        console.error('Failed to fetch assets:', err)
        setError(err?.response?.data?.error || 'Failed to load assets')
      } finally {
        setLoading(false)
      }
    }

    fetchAssets()
    const interval = setInterval(fetchAssets, 60000)
    return () => clearInterval(interval)
  }, [botAddress])

  if (!botAddress) return null

  return (
    <div className="w-full">
      {/* Header */}
      <div className="flex items-center justify-between px-2 py-2 mb-2">
        <span className="text-xs font-mono text-neon-green">
          ${totalUSD.toLocaleString()} USD
        </span>
      </div>

      {/* Content */}
      <div className="divide-y divide-border">
        {loading ? (
          <div className="px-4 py-8 text-center text-muted-foreground text-sm">
            Loading balances...
          </div>
        ) : error ? (
          <div className="px-4 py-8 text-center text-destructive text-sm">{error}</div>
        ) : assets.length === 0 ? (
          <div className="px-4 py-8 text-center text-muted-foreground text-sm">
            No assets found
          </div>
        ) : (
          assets.map((asset, i) => (
            <div key={`${asset.chainId}-${asset.symbol}-${i}`} className="flex items-center justify-between px-2 py-3 border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors rounded">
              {/* Left: Token info */}
              <div className="flex items-center gap-3">
                {asset.logoURI ? (
                  <img
                    src={asset.logoURI}
                    alt={asset.symbol}
                    className="w-8 h-8 rounded-full bg-muted"
                    onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                  />
                ) : (
                  <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center text-xs font-bold text-muted-foreground">
                    {asset.symbol.slice(0, 2)}
                  </div>
                )}
                <div>
                  <div className="font-semibold text-sm text-foreground">{asset.symbol}</div>
                  <div className="text-xs text-muted-foreground">
                    {CHAIN_NAMES[asset.chainId] || `Chain ${asset.chainId}`}
                  </div>
                </div>
              </div>

              {/* Right: Balance + USD value */}
              <div className="text-right">
                <div className="font-mono text-sm text-foreground">
                  {asset.amountFormatted}
                </div>
                <div className="text-xs text-muted-foreground">
                  ${asset.valueUSD.toLocaleString()} · ${parseFloat(asset.priceUSD).toLocaleString()}/ea
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
