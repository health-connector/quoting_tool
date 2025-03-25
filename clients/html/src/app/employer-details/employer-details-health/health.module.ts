import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

import { EmployerDetailsHealthComponent } from './employer-details-health.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
    imports: [
        CommonModule,
        RouterModule.forChild([
            {
                path: '',
                component: EmployerDetailsHealthComponent
            }
        ]),
        SharedModule,
        EmployerDetailsHealthComponent
    ]
})
export class HealthModule {}
