import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ApiRequestService {
  private http = inject(HttpClient);
  headers = new HttpHeaders({ 'Content-Type': 'application/json' });
  // The API version
  public version = 1.0;

  // URL to the API we want to use
  private api = environment.envApi;
  private cataract_api = environment.cataract_api;

  // Get the full URL to the API
  private getFullPath(url: any) {
    return `${this.api}/api/v${this.version}/${url}`;
  }

  private getCataractFullPath(url: any) {
    return `${this.cataract_api}/api/v${this.version}/${url}`;
  }

  // Make an authed GET request
  public authedGet(url: string, attrs?: any) {
    return this.http.get(this.getFullPath(url), { params: attrs });
  }

  // Make an authed POST request
  public authedPost(url: string, body: any) {
    return this.http.post(this.getFullPath(url), body);
  }

  // Make an authed PUT request
  public authedPut(url: string, body: any) {
    return this.http.put(this.getFullPath(url), body);
  }

  public authedCataractGet(url: string, attrs?: any) {
    return this.http.get(this.getCataractFullPath(url), { params: attrs });
  }
}
