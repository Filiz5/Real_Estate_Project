package com.team01.realestate.payload.response.business;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CityResponse {

    private Long id;
    private String name;
    private String countryName; // Şehrin ait olduğu ülkenin adı
    private List<String> districts;

}
