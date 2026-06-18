package com.eco.backend.my;

public class MyPageBadgeResponse {

    private final String id;
    private final String name;
    private final String description;
    private final String tone;
    private final String type;
    private final int sortOrder;

    public MyPageBadgeResponse(
            String id,
            String name,
            String description,
            String tone,
            String type,
            int sortOrder
    ) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.tone = tone;
        this.type = type;
        this.sortOrder = sortOrder;
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public String getTone() {
        return tone;
    }

    public String getType() {
        return type;
    }

    public int getSortOrder() {
        return sortOrder;
    }
}
