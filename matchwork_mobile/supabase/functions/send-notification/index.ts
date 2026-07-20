import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7"

console.log("Hello from send-notification!")

serve(async (req) => {
  try {
    const payload = await req.json()
    console.log("Webhook Payload:", payload)

    // Solo nos interesan las inserciones
    if (payload.type !== "INSERT") {
      return new Response("Not an insert, skipping.", { status: 200 })
    }

    const record = payload.record
    const table = payload.table

    let receiverId = ""
    let title = ""
    let body = ""

    if (table === "messages") {
      receiverId = record.receiver_id
      title = "Nuevo mensaje"
      body = record.text || "Alguien te ha enviado un mensaje."
    } else if (table === "requests") {
      receiverId = record.provider_id
      title = "Nueva solicitud de servicio"
      body = "Tienes una nueva solicitud de trabajo pendiente."
    } else {
      return new Response("Table not supported.", { status: 200 })
    }

    // Inicializar Supabase para buscar el token
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    )

    // Buscar el FCM Token del receptor
    const { data: profile, error } = await supabaseClient
      .from("profiles")
      .select("fcm_token")
      .eq("id", receiverId)
      .single()

    if (error || !profile?.fcm_token) {
      console.log(`No FCM token found for user ${receiverId}`)
      return new Response("No token found.", { status: 200 })
    }

    const fcmToken = profile.fcm_token

    // Llamar a Firebase para enviar la notificación Push
    const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")
    if (!serviceAccountStr) {
      console.error("Missing FIREBASE_SERVICE_ACCOUNT secret.")
      return new Response("Missing Firebase credentials.", { status: 500 })
    }

    const serviceAccount = JSON.parse(serviceAccountStr)
    
    // Generar el token de acceso usando una petición HTTP simple con JWT
    const { getBearerToken } = await import("https://deno.land/x/google_jwt@v1.0.0/mod.ts")
    
    const jwt = await getBearerToken({
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"]
    })

    const projectId = serviceAccount.project_id

    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body
        }
      }
    }

    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${jwt}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fcmPayload)
    })

    const result = await response.json()
    console.log("FCM Result:", result)

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
      status: response.ok ? 200 : 500,
    })

  } catch (error) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})
