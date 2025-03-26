import 'hammerjs';
import { enableProdMode, importProvidersFrom } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';


import { environment } from './environments/environment';
import { AppComponent } from './app/app.component';
import { SharedModule } from './app/shared/shared.module';
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
        loadChildren: () => import("./app/employer-details/employer-details.module").then((m) => m.EmployerDetailsModule)
    },
    {
        path: 'employer-details/health',
        loadChildren: () => import("./app/employer-details/employer-details-health/health.module").then((m) => m.HealthModule)
    },
    {
        path: 'employer-details/dental',
        loadChildren: () => import("./app/employer-details/employer-details-dental/dental.module").then((m) => m.DentalModule)
    }
];


if (environment.production) {
  enableProdMode();
}

bootstrapApplication(AppComponent, {
    providers: [
        importProvidersFrom(CommonModule, BrowserModule, FormsModule, ReactiveFormsModule, NgbModule, SweetAlert2Module.forRoot(), SharedModule),
        provideAnimations(),
        provideHttpClient(withInterceptorsFromDi()),
        provideRouter(routes)
    ]
})
  .catch(err => console.log(err));
