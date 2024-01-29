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

import org.apache.flink.configuration.Configuration;
import org.apache.flink.configuration.PipelineOptions;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public final class StreamTableEnvironmentFactory {
    public static final StreamTableEnvironmentFactory INSTANCE = new StreamTableEnvironmentFactory();

    public StreamTableEnvironment createStreamTableEnvironment(final FlinkConfig flinkConfig)
            throws StreamTableEnvironmentFactoryException {
        final Configuration configuration = Configuration.fromMap(flinkConfig.getFlinkConfiguration());
        try (StreamExecutionEnvironment bsEnv = StreamExecutionEnvironment.getExecutionEnvironment(configuration)) {
            if (flinkConfig.getCheckpointIntervalMs() != null) {
                bsEnv.enableCheckpointing(flinkConfig.getCheckpointIntervalMs());
                bsEnv.getConfig().setUseSnapshotCompression(true);
            }
            bsEnv.setMaxParallelism(96);

            final EnvironmentSettings environmentSettings = EnvironmentSettings.inStreamingMode();
            final StreamTableEnvironment streamTableEnvironment = StreamTableEnvironment.create(bsEnv,
                    environmentSettings);
            final Configuration config = streamTableEnvironment.getConfig().getConfiguration();
            config.set(PipelineOptions.NAME, flinkConfig.getJobName());
            return streamTableEnvironment;
        } catch (Exception e) { // NOPMD
            throw new StreamTableEnvironmentFactoryException(e);
        }
    }
}
