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

    public KafkaSaslSslConfig(@JsonProperty("bootstrap_servers") final String bootstrapServers,
            @JsonProperty("integration_type") final String integrationType,
            @JsonProperty("security_protocol") final String securityProtocol,
            @JsonProperty("sasl_ssl") final KafkaSaslSslConfigSaslSsl saslSsl) {
        this.bootstrapServers = bootstrapServers;
        this.integrationType = integrationType;
        this.securityProtocol = securityProtocol;
        this.saslSsl = saslSsl;
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
}
