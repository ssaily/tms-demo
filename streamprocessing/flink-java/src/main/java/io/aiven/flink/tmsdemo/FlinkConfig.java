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

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public final class FlinkConfig {
    private final Map<String, String> flinkConfiguration;
    private final Long checkpointIntervalMs;
    private final String jobName;

    public FlinkConfig(final String jobName) {
        this(new HashMap<>(), null, jobName);
    }

    public FlinkConfig(final Map<String, String> flinkConfiguration, final Long checkpointIntervalMs,
            final String jobName) {
        this.flinkConfiguration = new HashMap<>(flinkConfiguration);
        this.checkpointIntervalMs = checkpointIntervalMs;
        this.jobName = jobName;
    }

    public Map<String, String> getFlinkConfiguration() {
        return new HashMap<>(flinkConfiguration);
    }

    public Long getCheckpointIntervalMs() {
        return checkpointIntervalMs;
    }

    public String getJobName() {
        return jobName;
    }

    @Override
    public boolean equals(final Object object) {
        if (this == object) {
            return true;
        }
        if (object == null || getClass() != object.getClass()) {
            return false;
        }
        final FlinkConfig that = (FlinkConfig) object;
        return Objects.equals(flinkConfiguration, that.flinkConfiguration)
                && Objects.equals(checkpointIntervalMs, that.checkpointIntervalMs)
                && Objects.equals(jobName, that.jobName);
    }

    @Override
    public int hashCode() {
        return Objects.hash(flinkConfiguration, checkpointIntervalMs, jobName);
    }
}
