import { Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { FooterComponent } from './components/footer/footer.component';
import { HeaderComponent } from './components/header/header.component';

@Component({
  selector: 'app-root',
  template: `
    <app-header />
    <router-outlet />
    <app-footer />
  `,
  changeDetection: ChangeDetectionStrategy.Eager,
  imports: [HeaderComponent, RouterOutlet, FooterComponent],
})
export class AppComponent implements OnInit {
  ngOnInit() {
    localStorage.removeItem('employerDetails');
  }
}
