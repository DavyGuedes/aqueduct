import 'dart:async';

import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct/src/utilities/documented_element.dart';
import 'package:aqueduct/src/utilities/documented_element_analyzer_bridge.dart';
import 'package:isolate_executor/isolate_executor.dart';
import 'package:yaml/yaml.dart';

class OpenAPIBuilder extends Executable<Map<String, dynamic>> {
  OpenAPIBuilder(Map<String, dynamic> message)
      : pubspecContents = message["pubspec"] as String,
        configPath = message["configPath"] as String,
        title = message["title"] as String,
        description = message["description"] as String,
        version = message["version"] as String,
        termsOfServiceURL = message["termsOfServiceURL"] != null
            ? Uri.parse(message["termsOfServiceURL"] as String)
            : null,
        contactEmail = message["contactEmail"] as String,
        contactName = message["contactName"] as String,
        contactURL = message["contactURL"] != null
            ? Uri.parse(message["contactURL"] as String)
            : null,
        licenseURL = message["licenseURL"] != null
            ? Uri.parse(message["licenseURL"] as String)
            : null,
        licenseName = message["licenseName"] as String,
        hosts = (message["hosts"] as List<String>)
                ?.map((uri) => APIServerDescription(Uri.parse(uri)))
                ?.toList() ??
            [],
        resolveRelativeUrls = message["resolveRelativeUrls"] as bool,
        super(message);

  OpenAPIBuilder.input(Map<String, dynamic> variables) : super(variables);

  String pubspecContents;
  String configPath;
  String title;
  String description;
  String version;
  Uri termsOfServiceURL;
  String contactEmail;
  String contactName;
  Uri contactURL;
  Uri licenseURL;
  String licenseName;
  List<APIServerDescription> hosts;
  bool resolveRelativeUrls;

  @override
  Future<Map<String, dynamic>> execute() async {
    DocumentedElement.provider = AnalyzerDocumentedElementProvider();

    var config = ApplicationOptions()..configurationFilePath = configPath;

    final yaml = (loadYaml(pubspecContents) as Map<dynamic, dynamic>)
        .cast<String, dynamic>();
    var document = await Application.document(
        ApplicationChannel.defaultType, config, yaml);

    document.servers = hosts;
    if (title != null) {
      document.info ??= APIInfo.empty();
      document.info.title = title;
    }
    if (description != null) {
      document.info ??= APIInfo.empty();
      document.info.description = description;
    }
    if (version != null) {
      document.info ??= APIInfo.empty();
      document.info.version = version;
    }
    if (termsOfServiceURL != null) {
      document.info ??= APIInfo.empty();
      document.info.termsOfServiceURL = termsOfServiceURL;
    }
    if (contactEmail != null) {
      document.info ??= APIInfo.empty();
      document.info.contact ??= APIContact.empty();
      document.info.contact.email = contactEmail;
    }
    if (contactName != null) {
      document.info ??= APIInfo.empty();
      document.info.contact ??= APIContact.empty();
      document.info.contact.name = contactName;
    }
    if (contactURL != null) {
      document.info ??= APIInfo.empty();
      document.info.contact ??= APIContact.empty();
      document.info.contact.url = contactURL;
    }
    if (licenseURL != null) {
      document.info ??= APIInfo.empty();
      document.info.license ??= APILicense.empty();
      document.info.license.url = licenseURL;
    }
    if (licenseName != null) {
      document.info ??= APIInfo.empty();
      document.info.license ??= APILicense.empty();
      document.info.license.name = licenseName;
    }

    if (resolveRelativeUrls) {
      final baseUri =
          document.servers?.first?.url ?? Uri.parse("http://localhost:8888");
      document.components.securitySchemes.values?.forEach((scheme) {
        scheme.flows?.values?.forEach((flow) {
          if (flow.refreshURL != null && !flow.refreshURL.isAbsolute) {
            flow.refreshURL = baseUri.resolveUri(flow.refreshURL);
          }
          if (flow.authorizationURL != null && !flow.authorizationURL.isAbsolute) {
            flow.authorizationURL = baseUri.resolveUri(flow.authorizationURL);
          }
          if (flow.tokenURL != null && !flow.tokenURL.isAbsolute) {
            flow.tokenURL = baseUri.resolveUri(flow.tokenURL);
          }
        });
      });
    }

    return document.asMap();
  }

  static List<String> importsForPackage(String packageName) => [
        "package:aqueduct/aqueduct.dart",
        "package:$packageName/$packageName.dart",
        "package:yaml/yaml.dart",
        "package:aqueduct/src/utilities/documented_element.dart",
        "package:aqueduct/src/utilities/documented_element_analyzer_bridge.dart",
        "dart:convert",
        "dart:io"
      ];
}