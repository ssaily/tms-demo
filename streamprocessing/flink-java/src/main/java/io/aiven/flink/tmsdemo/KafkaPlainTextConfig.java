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

public final class KafkaPlainTextConfig {
    private final String bootstrapServers;

    private final String integrationType;

    private final String securityProtocol;

    private final String serviceName;

    private final String schemaRegistryUrl;

    public KafkaPlainTextConfig(@JsonProperty("bootstrap_servers") final String bootstrapServers,
            @JsonProperty("integration_type") final String integrationType,
            @JsonProperty("security_protocol") final String securityProtocol,
            @JsonProperty("service_name") final String serviceName,
            @JsonProperty("schema_registry_url") final String schemaRegistryUrl) {
        this.bootstrapServers = bootstrapServers;
        this.integrationType = integrationType;
        this.securityProtocol = securityProtocol;
        this.serviceName = serviceName;
        this.schemaRegistryUrl = schemaRegistryUrl;
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

    @JsonProperty("service_name")
    public String getServiceName() {
        return serviceName;
    }

    @JsonProperty("schema_registry_url")
    public String getSchemaRegistryUrl() {
        return schemaRegistryUrl;
    }
}
