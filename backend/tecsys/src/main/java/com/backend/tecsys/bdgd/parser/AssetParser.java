package com.backend.tecsys.bdgd.parser;

import com.backend.tecsys.bdgd.model.AssetFileRecord;

import java.io.InputStream;
import java.util.List;
import java.util.function.Consumer;

public interface AssetParser {
    List<AssetFileRecord> parse(InputStream inputStream, String defaultDistribuidora, String defaultRegiao);

    default void parseAndProcess(InputStream inputStream, String defaultDistribuidora, String defaultRegiao, Consumer<AssetFileRecord> consumer) {
        for (AssetFileRecord record : parse(inputStream, defaultDistribuidora, defaultRegiao)) {
            consumer.accept(record);
        }
    }
}
