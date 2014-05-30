//
//  ViewController.m
//  BLEModuleControl
//
//  Created by Sam Dickson on 5/29/14.
//  Copyright (c) 2014 Fluke Networks. All rights reserved.
//

#import "ViewController.h"
#define MTU 20
#define SEND_TYPE_STRING 0
#define SEND_TYPE_DATA 1

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblMeasurement;
@property (weak, nonatomic) IBOutlet GraphView *graphView;
@property (strong, nonatomic) IBOutlet UIView *WaveView;
@property (weak, nonatomic) IBOutlet UIButton *btnBeginTransfer;
@property (weak, nonatomic) IBOutlet UITextView *txtConsole;
@property (weak, nonatomic) IBOutlet UIButton *redButton;
@property (weak, nonatomic) IBOutlet UIButton *grnButton;
@end

@implementation ViewController

static NSString* const KServiceUUID = @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString* const KCharacteristicReadableUUID = @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString* const KCharacteristicWriteableUUID = @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
static BOOL RED_ON = false;
static BOOL GRN_ON = false;

NSMutableData *recvData;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.graphView.data = [[NSMutableArray alloc] initWithObjects: [NSNumber numberWithFloat:0.0f], nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch(central.state)
    {
        case CBCentralManagerStatePoweredOn:
            [self.manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:KServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
            //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Scanning for peripherals..."];
            NSLog(@"Scanning for peripherals...");
            break;
        default:
            //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Bluetooth LE is unsupported!"];
            NSLog(@"Bluetooth LE is unsupported.");
            break;
    }
}

- (IBAction)btnBeginTransferPressed:(id)sender
{
    self.data = [@"BEGIN_TX" dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheral writeValue:self.data forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (IBAction)grnButtonToggled:(id)sender
{
    if(GRN_ON)
    {
        [self.grnButton setImage:[UIImage imageNamed:@"led_off.png"] forState:UIControlStateNormal];
        self.data = [@"GRN_OFF" dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        [self.grnButton setImage:[UIImage imageNamed:@"grn_on.png"] forState:UIControlStateNormal];
        self.data = [@"GRN_ON" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    GRN_ON = !GRN_ON;
    [self.peripheral writeValue:self.data forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (IBAction)redButtonToggled:(id)sender
{
    if(RED_ON)
    {
        [self.redButton setImage:[UIImage imageNamed:@"led_off.png"] forState:UIControlStateNormal];
        self.data = [@"RED_OFF" dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        [self.redButton setImage:[UIImage imageNamed:@"red_on.png"] forState:UIControlStateNormal];
        self.data = [@"RED_ON" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    RED_ON = !RED_ON;
    [self.peripheral writeValue:self.data forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)sendData:(int)data_type
{
    if(self.dataIndex >= self.data.length)
    {
        return;
    }
    
    BOOL doneSending = NO;
    
    while(!doneSending)
    {
        NSInteger sendAmt = self.data.length - self.dataIndex;
        
        if(sendAmt > MTU)
        {
            sendAmt = MTU;
        }
        
        NSData *packet = [NSData dataWithBytes:self.data.bytes+self.dataIndex length:sendAmt];
        NSLog(@"Sending packet: %@", packet.description);
        
        switch(data_type)
        {
            case SEND_TYPE_STRING:
                [self.peripheral writeValue:packet forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
                break;
            case SEND_TYPE_DATA:
                [self.peripheral writeValue:packet forCharacteristic:self.dataCharacteristic type:CBCharacteristicWriteWithoutResponse];
                break;
        }
        
        self.dataIndex += sendAmt;
        
        if(self.dataIndex >= self.data.length)
        {
            switch(data_type)
            {
                case SEND_TYPE_STRING:
                    [self.peripheral writeValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    break;
                case SEND_TYPE_DATA:
                    [self.peripheral writeValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.dataCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    break;
            }
            doneSending = YES;
            return;
        }
        
        packet = nil;
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error writing to characteristic:", [error localizedDescription]];
        NSLog(@"Error writing to characteristic: %@ (code %d)", [error localizedDescription], [error code]);
    }
}

- (void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Found peripheral! Stopping scan."];
    [self.manager stopScan];
    
    if(self.peripheral != peripheral)
    {
        self.peripheral = peripheral;
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Connecting to peripheral: ", peripheral];
        NSLog(@"Connecting to peripheral %@", peripheral);
        [   self.manager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //[self.data setLength:0];
    [self.peripheral setDelegate:self];
    //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Connected!"];
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:KServiceUUID]]];
    //[self.disconnect setEnabled:YES];
    //self.status.text = [NSString stringWithFormat:@"Connected to %@", [peripheral.identifier UUIDString]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error discovering service: ", [error localizedDescription]];
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        //[self cleanup];
        return;
    }
    
    for(CBService *service in peripheral.services)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Found service with UUID: ", service.UUID];
        NSLog(@"Found service with UUID: %@", service.UUID);
        if([service.UUID isEqual:[CBUUID UUIDWithString:KServiceUUID]])
        {
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:KCharacteristicReadableUUID]] forService:service];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:KCharacteristicWriteableUUID]] forService:service];
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error discovering characteristic: ", [error localizedDescription]];
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        return;
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:KServiceUUID]])
    {
        for(CBCharacteristic *characteristic in service.characteristics)
        {
            //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Discovered characteristic with UUID: ", characteristic.UUID];
            //NSLog(@"Discovered characteristic with UUID: %@", characteristic.UUID);
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicReadableUUID]])
            {
                //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Discovered READABLE characteristic."];
                NSLog(@"Discovered READABLE characteristic");
                self.peripheralCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.peripheralCharacteristic];
            }
            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicWriteableUUID]])
            {
                //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Discovered WRITEABLE characteristic."];
                NSLog(@"Discovered WRITEABLE characteristic");
                self.writebackCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.writebackCharacteristic];
            }
            
        }
    }
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error changing notification state: ", [error localizedDescription]];
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
        return;
    }
    
    if(!([characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicReadableUUID]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicWriteableUUID]]))
    {
        return;
    }
    
    if(characteristic.isNotifying)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Notification began on ", characteristic];
        NSLog(@"Notification began on %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    }
    else
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Notification stopped on ", characteristic];
        NSLog(@"Notification has stopped on %@", characteristic);
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Error reading updated characteristic value: ", [error localizedDescription]];
        NSLog(@"Error reading updated characteristic value: %@", [error localizedDescription]);
        return;
    }
    
    
    NSString *str = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    if([self.graphView.data count] >= 7)
    {
        [self.graphView.data removeObjectsInRange:NSMakeRange(0, [self.graphView.data count])];
    }
    
        [self.lblMeasurement setText:[NSString stringWithFormat:@"%.2f kΩ", ([str floatValue] / 1000.0 * 9.6)]];
        [self.graphView.data addObject:[NSNumber numberWithFloat:[str floatValue] / 1000.0]];
    
    
    //NSLog(@"Added count is %d", [self.graphView.data count]);
    [self.graphView setNeedsDisplay];
    
    NSLog(@"Data in: %d", [str intValue]);
    
    
    /*if([stringFromData isEqualToString:@"EOM"])
    {
        if(recvData != nil)
        {
            //NSLog(@"DONE RECV");
            NSData *final = [[NSData alloc] initWithData:recvData];
            //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"[In]: ", final];
            NSString *str = [[NSString alloc] initWithData:final encoding:NSUTF8StringEncoding];
            NSLog(@"Data in: %d", [str intValue]);
            recvData = nil;
        }
    }
    else
    {
        if(recvData == nil)
        {
            recvData = [[NSMutableData alloc] initWithData:characteristic.value];
        }
        else
        {
            [recvData appendData:characteristic.value];
        }
    }*/
}




@end
