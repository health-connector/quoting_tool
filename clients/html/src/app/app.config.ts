import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideRouter } from '@angular/router';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { CustomDateParserFormatter } from './custom_date_parser_formatter';
import { SweetAlert2Module } from '@sweetalert2/ngx-sweetalert2';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { withInterceptorsFromDi, provideHttpClient, withXhr } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { provideAnimations } from '@angular/platform-browser/animations';
import { CommonModule } from '@angular/common';
import { ROUTES } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(ROUTES),
    provideAnimations(),
    provideHttpClient(withXhr(), withInterceptorsFromDi()),
    importProvidersFrom(NgbModule, SweetAlert2Module.forRoot(), FormsModule, ReactiveFormsModule, CommonModule),
    { provide: NgbDateParserFormatter, useClass: CustomDateParserFormatter },
  ],
};
