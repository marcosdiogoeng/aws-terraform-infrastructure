# ============================================================
# IDs de Políticas Gerenciadas pela AWS — Referência Rápida
# ============================================================
# Use esses locals no seu código raiz para referenciar
# as políticas gerenciadas sem precisar decorar os IDs.

locals {
  # -------------------------------------------------------
  # Cache Policies
  # -------------------------------------------------------
  cache_policy = {
    # Recomendada para conteúdo estático (S3)
    caching_optimized = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # Sem cache — ideal para APIs dinâmicas
    caching_disabled = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # Otimizada para compressão (Brotli + Gzip)
    caching_optimized_for_uncompressed_objects = "b2884449-e4de-46a7-ac36-70bc7f1ddd6d"

    # Elemental Media
    elemental_media_package = "08627262-05a9-4f76-9ded-b50ca2e3a84f"
  }

  # -------------------------------------------------------
  # Origin Request Policies
  # -------------------------------------------------------
  origin_request_policy = {
    # Encaminha headers CORS para S3
    cors_s3_origin = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"

    # Encaminha headers CORS para origens customizadas
    cors_custom_origin = "59781a5b-3903-41f3-afcb-af62929ccde1"

    # Todos os parâmetros de viewer (headers, cookies, query strings)
    all_viewer = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    # Todos os parâmetros exceto Host
    all_viewer_except_host_header = "b689b0a8-53d0-40ab-baf2-68738e2966ac"

    # Apenas parâmetros UserAgentRefererHeaders
    user_agent_referer_headers = "acba4595-bd28-49b8-b9fe-13317c0390fa"
  }

  # -------------------------------------------------------
  # Response Headers Policies
  # -------------------------------------------------------
  response_headers_policy = {
    # Headers de segurança recomendados
    security_headers = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    # CORS e segurança
    cors_with_preflight_and_security_headers = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"

    # Apenas CORS
    cors_and_security_headers = "e61eb60c-9c35-4d20-a928-2b84e02af89c"

    # Sem cache (no-store, no-cache)
    managed_cors_s3_origin_with_preflight = "5cc3b908-e619-4b99-88e5-2cf7f45965bd"
  }
}
