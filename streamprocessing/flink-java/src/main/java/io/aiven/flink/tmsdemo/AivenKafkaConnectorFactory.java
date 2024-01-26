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

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


import org.apache.commons.io.FileUtils;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.core.type.TypeReference;

public final class AivenKafkaConnectorFactory {
    protected static final Logger logger = LogManager.getLogger(AivenKafkaConnectorFactory.class.getName());
    public static final AivenKafkaConnectorFactory INSTANCE = new AivenKafkaConnectorFactory();

    public AivenKafkaConnector createAivenKafkaConnector(final String integrationId) throws IOException {
        final String integrationJson = readIntegrationJsonFile(integrationId);
        logger.debug(integrationJson);
        final String securityProtocol = determineSecurityProtocolOfIntegration(integrationJson);
        if ("SASL_SSL".equals(securityProtocol)) {
            return new AivenKafkaConnector(JsonMapper.readValue(integrationJson, KafkaSaslSslConfig.class));
        } else if ("PLAINTEXT".equals(securityProtocol)) {
            return new AivenKafkaConnector(JsonMapper.readValue(integrationJson, KafkaPlainTextConfig.class));
        } else {
            throw new IllegalStateException("Unknown security protocol: " + securityProtocol);
        }
    }

    private String readIntegrationJsonFile(final String integrationId) throws IOException {
        final String avnCredentialsDir = System.getenv("AVN_CREDENTIALS_DIR");
        if (avnCredentialsDir == null) {
            throw new IllegalStateException("AVN_CREDENTIALS_DIR not set");
        }
        final String integrationFileName = String.format("%s.json", integrationId);
        final File integrationJsonFile = Paths.get(avnCredentialsDir, integrationFileName).toFile();
        return FileUtils.readFileToString(integrationJsonFile, StandardCharsets.UTF_8);
    }

    private String determineSecurityProtocolOfIntegration(final String integrationJson) throws IOException {
        final TypeReference<HashMap<String, Object>> typeRef = new TypeReference<>() {
        };

        final Map<String, Object> integrationJsonAsMap = JsonMapper.readValue(integrationJson, typeRef);
        final String securityProtocolKey = "security_protocol";
        final String securityProtocol = (String) integrationJsonAsMap.get(securityProtocolKey);
        if (securityProtocol == null) {
            throw new IllegalStateException(securityProtocolKey + " not found in JSON: " + integrationJson);
        }
        return securityProtocol;
    }
}
