/*
 * Copyright 2021 Aiven Oy https://aiven.io
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

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public final class ConfigFiles {

    protected static final Logger logger = LogManager.getLogger(ConfigFiles.class.getName());

    public static final String CONFIG_PROPERTIES_FILE = "config.properties";
    public static final String JOB_SQL_FILE = "job.sql";
    public static final String TABLE_SQL_FILE_PATTERN = "table-%d.sql";
    public static final String KAFKA_PROPERTIES_FILE = "kafka.json";

    private final Path configPath;

    public ConfigFiles(final Path configPath) {
        this.configPath = configPath;
    }

    String readKafkaConfig() throws IOException {
        return readFile(KAFKA_PROPERTIES_FILE);
    }

    String readJobSQL() throws IOException {
        return readFile(JOB_SQL_FILE);
    }

    private String tableFileName(final int index) {
        return String.format(TABLE_SQL_FILE_PATTERN, index);
    }

    private String readTableSQL(final int index) throws IOException {
        final String fileName = tableFileName(index);
        try (InputStream inputStream = createInputStream(fileName)) {
            if (inputStream == null) {
                throw new FileNotFoundException(fileName);
            }
            return readStream(inputStream);
        }
    }

    FlinkConfig readJobConfig() throws IOException {
        final Properties properties = new Properties();
        try (InputStream inputStream = createInputStream(CONFIG_PROPERTIES_FILE)) {
            if (inputStream == null) {
                throw new FileNotFoundException(CONFIG_PROPERTIES_FILE);
            }
            properties.load(inputStream);
        }

        Long checkpointIntervalMs = null;
        if (properties.getProperty("checkpoint_interval_ms") != null) {
            checkpointIntervalMs = Long.parseLong(properties.getProperty("checkpoint_interval_ms"));
        }

        final Map<String, String> flinkConfig = new HashMap<>();
        for (final Map.Entry<Object, Object> entry : properties.entrySet()) {
            final String key = (String) entry.getKey();
            final String value = (String) entry.getValue();
            if (key.startsWith("flink.")) {
                final String keyWithoutFlinkPrefix = key.substring("flink.".length());
                flinkConfig.put(keyWithoutFlinkPrefix, value);
            }
        }
        return new FlinkConfig(flinkConfig, checkpointIntervalMs, properties.getProperty("job_name"));
    }

    private boolean tableSQLExists(final int index) throws IOException {
        try (InputStream inputStream = createInputStream(tableFileName(index))) {
            return inputStream != null;
        }
    }

    List<String> readTableSQLs() throws IOException {
        final List<String> tableSQLs = new ArrayList<>();
        int index = 1;
        while (tableSQLExists(index)) {
            tableSQLs.add(readTableSQL(index));
            index++;
        }

        if (tableSQLs.isEmpty()) {
            throw new FileNotFoundException("No table sql file for pattern " + TABLE_SQL_FILE_PATTERN);
        }

        return tableSQLs;
    }

    private String readFile(final String fileName) throws IOException {
        try (InputStream inputStream = createInputStream(fileName)) {
            if (inputStream == null) {
                throw new FileNotFoundException(fileName);
            }
            return readStream(inputStream);
        }
    }

    private String readStream(final InputStream inputStream) throws IOException {
        return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
    }

    private InputStream createInputStream(final String fileName) throws FileNotFoundException {
        InputStream inputStream = ConfigFiles.class.getResourceAsStream(fileName);
        if (inputStream != null) {
            return inputStream;
        }

        String mappedFileName;
        if (this.configPath == null) {
            mappedFileName = fileName;
        } else {
            mappedFileName = this.configPath.resolve(fileName).toString();
        }

        logger.info("Load configuration from {}", mappedFileName);
        inputStream = new FileInputStream(mappedFileName); // NOPMD
        return inputStream;
    }
}
