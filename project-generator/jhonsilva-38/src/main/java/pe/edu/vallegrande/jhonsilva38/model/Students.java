package pe.edu.vallegrande.jhonsilva38.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "STUDENTS")
public class Students {

    @Id
    private Long id;

    private String name;
    private String lastName;
    private String country;
    private String email;

    private String status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}