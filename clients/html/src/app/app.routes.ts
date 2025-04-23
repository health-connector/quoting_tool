import { Routes } from '@angular/router';

export const ROUTES: Routes = [
  {
    path: '',
    redirectTo: 'employer-details',
    pathMatch: 'full',
  },
  {
    path: 'employer-details',
    loadComponent: () =>
      import('../app/views/employer-details/employer-details.component').then((c) => c.EmployerDetailsComponent),
  },
  {
    path: 'employer-details/health',
    loadComponent: () =>
      import('../app/views/employer-details-health/employer-details-health.component').then(
        (c) => c.EmployerDetailsHealthComponent,
      ),
  },
  {
    path: 'employer-details/dental',
    loadComponent: () =>
      import('../app/views/employer-details-dental/employer-details-dental.component').then(
        (c) => c.EmployerDetailsDentalComponent,
      ),
  },
  {
    path: '**',
    redirectTo: 'employer-details',
  },
];
