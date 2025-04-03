import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
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
  private getFullPath(url: string): string {
    return `${this.api}/api/v${this.version}/${url}`;
  }

  private getCataractFullPath(url: string): string {
    return `${this.cataract_api}/api/v${this.version}/${url}`;
  }

  // Make an authed GET request
  public authedGet<T>(
    url: string,
    params?: Record<string, string | number | boolean | ReadonlyArray<string | number | boolean>>,
  ): Observable<T> {
    return this.http.get<T>(this.getFullPath(url), { params });
  }

  // Make an authed POST request
  public authedPost<T, D>(url: string, body: D): Observable<T> {
    return this.http.post<T>(this.getFullPath(url), body);
  }

  // Make an authed PUT request
  public authedPut<T, D>(url: string, body: D): Observable<T> {
    return this.http.put<T>(this.getFullPath(url), body);
  }

  public authedCataractGet<T>(
    url: string,
    params?: Record<string, string | number | boolean | ReadonlyArray<string | number | boolean>>,
  ): Observable<T> {
    return this.http.get<T>(this.getCataractFullPath(url), { params });
  }
}
