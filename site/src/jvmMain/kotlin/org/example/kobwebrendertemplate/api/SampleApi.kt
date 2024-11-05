package org.example.kobwebrendertemplate.api

import com.varabyte.kobweb.api.Api
import com.varabyte.kobweb.api.ApiContext
import com.varabyte.kobweb.api.http.setBodyText
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.example.kobwebrendertemplate.DomainObject

/** Responds at http://localhost:8080/api/sample */
@Api("/sample")
suspend fun sample(ctx: ApiContext) {
  ctx.res.status = 200
  val domainObject = DomainObject(id = 42, text = "looks good chief!")
  val json = Json.encodeToString(domainObject)
  ctx.res.setBodyText(json)
}
