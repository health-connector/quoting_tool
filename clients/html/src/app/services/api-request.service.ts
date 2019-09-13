import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ApiRequestService {
  headers = new HttpHeaders({'Content-Type': 'application/json'});
  constructor(private http: HttpClient) { }

  // The API version
  public version = 1.0;

  // URL to the API we want to use
  private api = environment.envApi;


  // Get the full URL to the API
  private getFullPath(url: any) {
    return (`${this.api}/api/v${this.version}/${url}`);
  }

  // Make an authed GET request
  public authedGet(url: string) {
    return this.http.get(this.getFullPath(url));
  }

  // Make an authed POST request
  public authedPost(url: string, body: any) {
    return this.http.post(this.getFullPath(url), body);
  }

  // Make an authed PUT request
  public authedPut(url: string, body: any) {
    return this.http.put(this.getFullPath(url), body);
  }

}