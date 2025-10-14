import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPorts from '@salesforce/apex/ReadinessController.getPorts';
import assessReadiness from '@salesforce/apex/ReadinessController.assessReadiness';
import getPortStatus from '@salesforce/apex/ReadinessController.getPortStatus';

export default class ReadinessMap extends LightningElement {
    @track mapMarkers = [];
    @track selectedPort = null;
    @track showModal = false;
    @track isAssessing = false;
    @track mapCenter = { location: { Latitude: 39.8283, Longitude: -98.5795 } }; // Default: US center
    @track zoomLevel = 4;
    
    wiredPortsResult;
    pollInterval;
    
    // Wire service to get ports
    @wire(getPorts)
    wiredPorts(result) {
        this.wiredPortsResult = result;
        if (result.data) {
            this.mapMarkers = result.data.map(port => {
                return {
                    location: {
                        Latitude: port.Geopoint__Latitude__s,
                        Longitude: port.Geopoint__Longitude__s
                    },
                    title: port.Name,
                    description: this.getPortDescription(port),
                    icon: this.getMarkerIcon(port),
                    value: port.Id
                };
            });
        } else if (result.error) {
            this.showToast('Error', 'Error loading ports: ' + result.error.body.message, 'error');
        }
    }
    
    getPortDescription(port) {
        let desc = `Sector: ${port.CBP_Sector__r?.Name || 'N/A'}`;
        if (port.Readiness_Score__c) {
            desc += `\nReadiness Score: ${port.Readiness_Score__c}`;
        }
        if (port.Assessment_Status__c) {
            desc += `\nStatus: ${port.Assessment_Status__c}`;
        }
        return desc;
    }
    
    getMarkerIcon(port) {
        // Color code markers based on readiness score
        if (!port.Readiness_Score__c) return 'standard:location';
        if (port.Readiness_Score__c >= 75) return 'standard:approval';
        if (port.Readiness_Score__c >= 50) return 'standard:warning';
        return 'standard:alert';
    }
    
    handleMarkerSelect(event) {
        const portId = event.detail.selectedMarkerValue;
        const port = this.wiredPortsResult.data.find(p => p.Id === portId);
        
        if (port) {
            this.selectedPort = port;
            this.showModal = true;
            
            // Center map on selected port
            this.mapCenter = {
                location: {
                    Latitude: port.Geopoint__Latitude__s,
                    Longitude: port.Geopoint__Longitude__s
                }
            };
            this.zoomLevel = 10; // Zoom in to the port
        }
    }
    
    closeModal() {
        this.showModal = false;
        this.selectedPort = null;
        this.stopPolling();
        
        // Reset map to default view
        this.mapCenter = { location: { Latitude: 39.8283, Longitude: -98.5795 } };
        this.zoomLevel = 4;
    }
    
    handleAssess() {
        if (!this.selectedPort) return;
        
        this.isAssessing = true;
        
        assessReadiness({ portId: this.selectedPort.Id })
            .then(result => {
                this.showToast('Success', result, 'success');
                // Start polling for updates
                this.startPolling();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isAssessing = false;
            });
    }
    
    startPolling() {
        // Poll every 3 seconds for status updates
        this.pollInterval = setInterval(() => {
            this.checkPortStatus();
        }, 3000);
    }
    
    stopPolling() {
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
            this.pollInterval = null;
        }
        this.isAssessing = false;
    }
    
    checkPortStatus() {
        if (!this.selectedPort) {
            this.stopPolling();
            return;
        }
        
        getPortStatus({ portId: this.selectedPort.Id })
            .then(port => {
                this.selectedPort = port;
                
                // Stop polling if assessment is complete or errored
                if (port.Assessment_Status__c === 'Complete' || 
                    port.Assessment_Status__c === 'Error') {
                    this.stopPolling();
                    
                    // Refresh the map markers
                    return refreshApex(this.wiredPortsResult);
                }
            })
            .catch(error => {
                console.error('Error polling status:', error);
                this.stopPolling();
            });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
    
    get hasSelectedPort() {
        return this.selectedPort !== null;
    }
    
    get assessButtonLabel() {
        return this.isAssessing ? 'Assessing...' : 'Assess Readiness';
    }
    
    get assessButtonDisabled() {
        return this.isAssessing || 
               this.selectedPort?.Assessment_Status__c === 'In Progress';
    }
    
    get readinessScoreClass() {
        if (!this.selectedPort?.Readiness_Score__c) return '';
        const score = this.selectedPort.Readiness_Score__c;
        if (score >= 75) return 'score-high';
        if (score >= 50) return 'score-medium';
        return 'score-low';
    }
    
    disconnectedCallback() {
        this.stopPolling();
    }
}
