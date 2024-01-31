/*
 * Copyright 2024 Aiven Oy https://aiven.io
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.aiven.flink.tmsdemo;

import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.annotation.JsonProperty;

public final class KafkaSaslSslConfig {
    private final String bootstrapServers;

    private final String integrationType;

    private final KafkaSaslSslConfigSaslSsl saslSsl;

    private final String securityProtocol;

    private final SchemaRegistryConfig schemaRegistryConfig;

    public static class KafkaSaslSslConfigSaslSsl {
        private final String saslMechanism;

        private final String saslPassword;

        private final String saslUsername;

        private final String sslCaCert;

        @SuppressWarnings("PMD.LongVariable")
        private final String sslEndpointIdentificationAlgorithm;

        @SuppressWarnings("PMD.LongVariable")
        private KafkaSaslSslConfigSaslSsl(@JsonProperty("sasl_mechanism") final String saslMechanism,
                @JsonProperty("sasl_password") final String saslPassword,
                @JsonProperty("sasl_username") final String saslUsername,
                @JsonProperty("ssl_ca_cert") final String sslCaCert,
                @JsonProperty("ssl_endpoint_identification_algorithm") final String sslEndpointIdentificationAlgorithm) {
            this.saslMechanism = saslMechanism;
            this.saslPassword = saslPassword;
            this.saslUsername = saslUsername;
            this.sslCaCert = sslCaCert;
            this.sslEndpointIdentificationAlgorithm = sslEndpointIdentificationAlgorithm;
        }

        @JsonProperty("sasl_mechanism")
        public String getSaslMechanism() {
            return saslMechanism;
        }

        @JsonProperty("sasl_password")
        public String getSaslPassword() {
            return saslPassword;
        }

        @JsonProperty("sasl_username")
        public String getSaslUsername() {
            return saslUsername;
        }

        @JsonProperty("ssl_ca_cert")
        public String getSslCaCert() {
            return sslCaCert;
        }

        @JsonProperty("ssl_endpoint_identification_algorithm")
        public String getSslEndpointIdentificationAlgorithm() {
            return sslEndpointIdentificationAlgorithm;
        }
    }

    public static class SchemaRegistryConfig {
        private final String authCredentialsSource;
        private final String authUserInfo;
        private final String schemaRegistryUrl;

        private SchemaRegistryConfig(@JsonProperty("basic-auth.credentials-source") final String authCredentialsSource,
            @JsonProperty("basic-auth.user-info") final String authUserInfo,
            @JsonProperty("schema-registry.url") final String schemaRegistryUrl) {
                this.authCredentialsSource = authCredentialsSource;
                this.authUserInfo = authUserInfo;
                this.schemaRegistryUrl = schemaRegistryUrl;
            }
        @JsonProperty("basic-auth.credentials-source")
        public String getCredentialsSsource() {
            return authCredentialsSource;
        }

        @JsonProperty("basic-auth.user-info")
        public String getUserInfo() {
            return authUserInfo;
        }

        @JsonProperty("schema-registry.url")
        public String getUrl() {
            return schemaRegistryUrl;
        }
    }

    public KafkaSaslSslConfig(@JsonProperty("bootstrap_servers") final String bootstrapServers,
            @JsonProperty("integration_type") final String integrationType,
            @JsonProperty("security_protocol") final String securityProtocol,
            @JsonProperty("sasl_ssl") final KafkaSaslSslConfigSaslSsl saslSsl,
            @JsonProperty("schema_registry") final SchemaRegistryConfig schemaRegistryConfig) {
        this.bootstrapServers = bootstrapServers;
        this.integrationType = integrationType;
        this.securityProtocol = securityProtocol;
        this.saslSsl = saslSsl;
        this.schemaRegistryConfig = schemaRegistryConfig;
    }

    @JsonProperty("bootstrap_servers")
    public String getBootstrapServers() {
        return bootstrapServers;
    }

    @JsonProperty("integration_type")
    public String getIntegrationType() {
        return integrationType;
    }

    @JsonProperty("security_protocol")
    public String getSecurityProtocol() {
        return securityProtocol;
    }

    @JsonProperty("sasl_ssl")
    public KafkaSaslSslConfigSaslSsl getSaslSsl() {
        return saslSsl;
    }

    @JsonProperty("schema_registry")
    public SchemaRegistryConfig getSchemaRegistry() {
        return schemaRegistryConfig;
    }
}
