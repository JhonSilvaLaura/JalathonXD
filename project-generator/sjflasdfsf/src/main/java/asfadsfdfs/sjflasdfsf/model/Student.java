package asfadsfdfs.sjflasdfsf.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "STUDENT")
public class Student {

    @Id
    private Long id;

    private String name;
    private String lastName;
    private String country;

    private String status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}