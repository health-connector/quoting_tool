import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbDateAdapter, NgbDateNativeAdapter, NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { EmployerDetailsDentalComponent } from './employer-details-dental.component';
import { SharedModule } from '../../shared/shared.module';
import { RouterModule } from '@angular/router';

@NgModule({
    imports: [
        CommonModule, NgbModule,
        RouterModule.forChild([
            {
                path: '',
                component: EmployerDetailsDentalComponent
            }
        ]),
        SharedModule,
        EmployerDetailsDentalComponent
    ],
    exports: [EmployerDetailsDentalComponent]
    // providers: [{ provide: NgbDateAdapter, useClass: NgbDateNativeAdapter }]
})
export class DentalModule {}
