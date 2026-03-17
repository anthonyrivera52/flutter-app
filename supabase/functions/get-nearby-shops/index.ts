import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { latitude, longitude, radiusKm = 10 } = await req.json();

    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      return jsonResponse({ error: 'latitude and longitude are required.' }, 400);
    }

    const { data, error } = await adminClient
      .from('locations')
      .select('id,name,image_url,address_line1,latitude,longitude,is_active,organizations(brand_logo_url)')
      .eq('is_active', true);

    if (error) return jsonResponse({ error: error.message }, 500);

    const toRad = (value: number) => (value * Math.PI) / 180;
    const distanceKm = (lat1: number, lng1: number, lat2: number, lng2: number) => {
      const R = 6371;
      const dLat = toRad(lat2 - lat1);
      const dLng = toRad(lng2 - lng1);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    };

    const nearby = ((data as any[]) ?? [])
      .map((loc) => {
        const dist = distanceKm(latitude, longitude, loc.latitude, loc.longitude);
        return {
          id: loc.id,
          name: loc.name,
          logoUrl: loc.image_url || loc.organizations?.brand_logo_url || '',
          address: loc.address_line1 || '',
          schedule: '08:00 AM - 10:00 PM', // Fallback as location doesn't have a schedule directly
          latitude: loc.latitude,
          longitude: loc.longitude,
          serviceRadiusKm: 10, // Fallback as we don't have service_radius_km in locations
          distanceKm: Number(dist.toFixed(2)),
          isActive: loc.is_active
        };
      })
      .filter((shop) => shop.distanceKm <= Math.min(shop.serviceRadiusKm ?? radiusKm, radiusKm))
      .sort((a, b) => a.distanceKm - b.distanceKm);

    return jsonResponse({ shops: nearby });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
