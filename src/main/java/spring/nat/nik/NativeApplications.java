package spring.nat.nik;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;

@SpringBootApplication
public class NativeApplications {

    public static void main(String[] args) {
        System.exit(
                SpringApplication.exit(new SpringApplicationBuilder(NativeApplications.class)
                        .web(WebApplicationType.NONE)
                        .run(args))
        );
    }
}
