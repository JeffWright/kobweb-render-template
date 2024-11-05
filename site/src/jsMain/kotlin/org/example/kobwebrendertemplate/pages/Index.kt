package org.example.kobwebrendertemplate.pages

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.varabyte.kobweb.browser.api
import com.varabyte.kobweb.compose.foundation.layout.Column
import com.varabyte.kobweb.compose.ui.modifiers.*
import com.varabyte.kobweb.core.Page
import com.varabyte.kobweb.silk.components.forms.Button
import com.varabyte.kobweb.silk.theme.colors.ColorSchemes
import kotlinx.browser.window
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import org.example.kobwebrendertemplate.DomainObject
import org.example.kobwebrendertemplate.components.layouts.PageLayout
import org.jetbrains.compose.web.dom.Text

val scope = CoroutineScope(SupervisorJob())

@Page
@Composable
fun HomePage() {
  PageLayout("Home") {
    var apiResponse by remember { mutableStateOf("---") }
    Column {
      Button(
        onClick = {
          apiResponse = "fetching ....."
          scope.launch {
            apiResponse =
              runCatching {
                  window.api
                    .get("sample")
                    .decodeToString()
                    .let { Json.decodeFromString<DomainObject>(it) }
                    .let { "${it.id} // ${it.text}" }
                }
                .getOrElse { "error" }
          }
        },
        colorScheme = ColorSchemes.Blue,
      ) {
        Text("Call the API")
      }
    }
    Text("Response: $apiResponse")
  }
}
