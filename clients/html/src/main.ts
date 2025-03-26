import 'hammerjs';
import { enableProdMode, importProvidersFrom } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { environment } from './environments/environment';
import { AppComponent } from './app/app.component';

import { SweetAlert2Module } from '@sweetalert2/ngx-sweetalert2';
import { provideRouter, Routes } from '@angular/router';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { withInterceptorsFromDi, provideHttpClient } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { provideAnimations } from '@angular/platform-browser/animations';
import { BrowserModule, bootstrapApplication } from '@angular/platform-browser';
import { CommonModule } from '@angular/common';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'employer-details',
    pathMatch: 'full'
  },
  {
    path: 'employer-details',
    loadComponent: () =>
      import('./app/employer-details/employer-details.component').then((m) => m.EmployerDetailsComponent)
  },
  {
    path: 'employer-details/health',
    loadComponent: () =>
      import('./app/employer-details/employer-details-health/employer-details-health.component').then(
        (m) => m.EmployerDetailsHealthComponent
      )
  },
  {
    path: 'employer-details/dental',
    loadComponent: () =>
      import('./app/employer-details/employer-details-dental/employer-details-dental.component').then(
        (m) => m.EmployerDetailsDentalComponent
      )
  }
];

if (environment.production) {
  enableProdMode();
}

bootstrapApplication(AppComponent, {
  providers: [
    importProvidersFrom(
      CommonModule,
      BrowserModule,
      FormsModule,
      ReactiveFormsModule,
      NgbModule,
      SweetAlert2Module.forRoot()
    ),
    provideAnimations(),
    provideHttpClient(withInterceptorsFromDi()),
    provideRouter(routes)
  ]
}).catch((err) => console.log(err));
