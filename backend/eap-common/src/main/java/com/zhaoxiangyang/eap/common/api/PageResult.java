package com.zhaoxiangyang.eap.common.api;

import java.util.List;
import java.util.Objects;

/**
 * Unified page response.
 */
public record PageResult<T>(
        List<T> list,
        int pageNum,
        int pageSize,
        long total,
        long pages
) {

    public PageResult {
        list = List.copyOf(Objects.requireNonNull(list, "list must not be null"));

        if (pageNum < 1) {
            throw new IllegalArgumentException("pageNum must be at least 1");
        }

        if (pageSize < 1 || pageSize > 100) {
            throw new IllegalArgumentException("pageSize must be between 1 and 100");
        }

        if (total < 0 || pages < 0) {
            throw new IllegalArgumentException("total and pages must not be negative");
        }
    }

    public static <T> PageResult<T> of(List<T> list, int pageNum, int pageSize, long total) {
        long pages = total == 0 ? 0 : (total + pageSize - 1) / pageSize;
        return new PageResult<>(list, pageNum, pageSize, total, pages);
    }
}
