import { LightningElement,wire,track,api } from 'lwc';
import getAnnouncement from '@salesforce/apex/getAnnouncement.getAnnouncements';
import {loadStyle} from 'lightning/platformResourceLoader';
import announcementComponent from '@salesforce/resourceUrl/announcementComponent';

export default class AnnouncementComponent extends LightningElement {

    @track announcementsData=[];
    
    @wire(getAnnouncement,{})
    announcements({data, error}) {
        if(data){
                console.log(JSON.stringify(data));
                this.hasRecords = data.length == 0 ? false : true; 
                this.announcementsData = data;
                
        }
        else if (error){
            console.log('(error---> ' + JSON.stringify(error));
        }
    }
    renderedCallback(){
        Promise.all([loadStyle(this,announcementComponent+'/announcementComponent.css')])
    }
}