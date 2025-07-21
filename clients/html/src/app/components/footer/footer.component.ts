import { Component } from '@angular/core';

@Component({
  selector: 'app-footer',
  template: `
    <div class="footer">
      <div class="container">
        <div class="row">
          <div class="col-6">
            <i class="far fa-copyright"></i> 2017-{{ currentYear }} Massachusetts Health Connector. All Rights Reserved.
          </div>
          <div class="col-6">
            <ul class="list-unstyled text-end">
              <li class=""><i class="fas fa-envelope"></i> smallbusiness&#64;mahealthconnector.org</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class FooterComponent {
  currentYear: number;

  ngOnInit() {
    this.currentYear = new Date().getFullYear();
  }
}
